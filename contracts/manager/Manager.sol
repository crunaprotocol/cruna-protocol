// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IAccountGuardian} from "@tokenbound/contracts/interfaces/IAccountGuardian.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {SignatureValidator} from "../utils/SignatureValidator.sol";

import {ProtectedNFT} from "../protected/ProtectedNFT.sol";
import {Actor} from "./Actor.sol";
import {IManager} from "./IManager.sol";
import {Versioned} from "../utils/Versioned.sol";

// TODO maybe remove it
import "@tokenbound/contracts/utils/Errors.sol" as Errors;

//import {console} from "hardhat/console.sol";

contract Manager is IManager, Actor, Context, Versioned, ERC721Holder, UUPSUpgradeable, IERC1271 {
  using ECDSA for bytes32;
  using Strings for uint256;

  error TimestampZero();
  error Forbidden();
  error NotTheTokenOwner();
  error ProtectorNotFound();
  error AssociatedToAnotherOwner();
  error ProtectorAlreadySet();
  error ProtectorAlreadySetByYou();
  error NotAProtector();
  error NotPermittedWhenProtectorsAreActive();
  error TimestampInvalidOrExpired();
  error WrongDataOrNotSignedByProtector();
  error WrongDataOrNotSignedByProposedProtector();
  error SignatureAlreadyUsed();
  error QuorumCannotBeZero();
  error QuorumCannotBeGreaterThanSentinels();
  error InheritanceNotConfigured();
  error StillAlive();
  error InconsistentRecipient();
  error NotASentinel();
  error RequestAlreadyApproved();
  error Unauthorized();
  error NotAnActiveProtector();
  error CannotBeYourself();
  error NotTheFirstProtector();
  error FirstProtectorNotFound();

  bool public constant IS_MANAGER = true;
  bool public constant IS_NOT_MANAGER = false;

  IAccountGuardian public guardian;
  SignatureValidator public signatureValidator;
  ProtectedNFT public vault;

  InheritanceRequest internal _inheritanceRequest;

  InheritanceConf internal _inheritanceConf;

  mapping(bytes32 => bool) public usedSignatures;

  modifier onlyTokenOwner() {
    if (vault.ownerOf(tokenId()) != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  // @dev see {IManager-init}
  // this must be execute immediately after the deployment
  function init(address guardian_, address signatureValidator_) external {
    if (msg.sender != tokenAddress()) revert Forbidden();
    guardian = IAccountGuardian(guardian_);
    signatureValidator = SignatureValidator(signatureValidator_);
    vault = ProtectedNFT(msg.sender);
  }

  function _authorizeUpgrade(address implementation) internal virtual override {
    if (!guardian.isTrustedImplementation(implementation)) revert Errors.InvalidImplementation();
    if (!_isValidSigner(msg.sender)) revert Errors.NotAuthorized();
  }

  // ERC6551 partial implementation

  function isValidSigner(address signer, bytes calldata) external view virtual returns (bytes4) {
    if (_isValidSigner(signer)) {
      return IERC6551Account.isValidSigner.selector;
    }

    return bytes4(0);
  }

  function isValidSignature(bytes32 hash, bytes memory signature) external view virtual returns (bytes4 magicValue) {
    bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

    if (isValid) {
      return IERC1271.isValidSignature.selector;
    }

    return bytes4(0);
  }

  function token() public view virtual returns (uint256, address, uint256) {
    return ERC6551AccountLib.token();
  }

  function owner() public view virtual returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = token();
    if (chainId != block.chainid) return address(0);

    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  function _isValidSigner(address signer) internal view virtual returns (bool) {
    return signer == owner();
  }

  // end ERC6551

  function tokenAddress() public view returns (address) {
    (, address tokenContract_, ) = token();
    return tokenContract_;
  }

  function tokenId() public view returns (uint256) {
    (, , uint256 tokenId_) = token();
    return tokenId_;
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    // This contract is not supposed to own vaults itself
    if (vault.balanceOf(address(this)) > 0) revert Errors.OwnershipCycle();
    return this.onERC721Received.selector;
  }

  // actors

  // @dev Counts the protectors.
  function countActiveProtectors() public view override returns (uint256) {
    return _actorLength(PROTECTOR);
  }

  // @dev Find a specific protector
  function findProtectorIndex(address protector_) public view override returns (uint256) {
    return _findActorIndex(protector_, PROTECTOR);
  }

  // @dev Returns true if the address is a protector.
  // @param protector_ The protector address.
  function isAProtector(address protector_) public view returns (bool) {
    return _isActiveActor(protector_, PROTECTOR);
  }

  // @dev Returns the list of protectors.
  function listProtectors() public view override returns (address[] memory) {
    return _listActiveActors(PROTECTOR);
  }

  function hasProtectors() public view override returns (bool) {
    return _actorLength(PROTECTOR) > 0;
  }

  // @dev see {IManager-setProtector}
  function setProtector(
    address protector_,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    _setSignedActor("PROTECTOR", protector_, PROTECTOR, status, timestamp, validFor, signature, IS_MANAGER);
    emit ProtectorUpdated(_msgSender(), protector_, status);
    if (status) {
      if (countActiveProtectors() == 1) {
        vault.emitLockedEvent(tokenId(), true);
      }
    } else {
      if (countActiveProtectors() == 0) {
        vault.emitLockedEvent(tokenId(), false);
      }
    }
  }

  // @dev see {IManager-getProtectors}
  function getProtectors() external view override returns (address[] memory) {
    return getActors(PROTECTOR);
  }

  // safe recipients
  // @dev see {IManager-setSafeRecipient}
  function setSafeRecipient(
    address recipient,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external override onlyTokenOwner {
    _setSignedActor("SAFE_RECIPIENT", recipient, SAFE_RECIPIENT, status, timestamp, validFor, signature, IS_NOT_MANAGER);
    emit SafeRecipientUpdated(_msgSender(), recipient, status);
  }

  // @dev see {IManager-isSafeRecipient}
  function isSafeRecipient(address recipient) public view override returns (bool) {
    return _findActorIndex(recipient, SAFE_RECIPIENT) != MAX_ACTORS;
  }

  // @dev see {IManager-getSafeRecipients}
  function getSafeRecipients() external view override returns (address[] memory) {
    return getActors(SAFE_RECIPIENT);
  }

  // sentinels and beneficiaries
  // @dev see {IManager-setSentinel}
  function setSentinel(
    address sentinel,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external override onlyTokenOwner {
    _setSignedActor("SENTINEL", sentinel, SENTINEL, status, timestamp, validFor, signature, IS_NOT_MANAGER);
    emit SentinelUpdated(_msgSender(), sentinel, status);
  }

  // @dev see {IManager-configureInheritance}
  // allow when protectors are active
  function configureInheritance(uint256 quorum, uint256 proofOfLifeDurationInDays) external onlyTokenOwner {
    if (countActiveProtectors() > 0) revert NotPermittedWhenProtectorsAreActive();
    if (quorum == 0) revert QuorumCannotBeZero();
    if (quorum > _actorLength(SENTINEL)) revert QuorumCannotBeGreaterThanSentinels();
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf = InheritanceConf(quorum, proofOfLifeDurationInDays, block.timestamp);
    delete _inheritanceRequest;
    emit InheritanceConfigured(_msgSender(), quorum, proofOfLifeDurationInDays);
  }

  // @dev see {IManager-getSentinelsAndInheritanceData}
  function getSentinelsAndInheritanceData()
    external
    view
    returns (address[] memory, InheritanceConf memory, InheritanceRequest memory)
  {
    return (getActors(SENTINEL), _inheritanceConf, _inheritanceRequest);
  }

  // @dev see {IManager-proofOfLife}
  function proofOfLife() external onlyTokenOwner {
    if (_inheritanceConf.proofOfLifeDurationInDays == 0) revert InheritanceNotConfigured();
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf.lastProofOfLife = block.timestamp;
    delete _inheritanceRequest;
    emit ProofOfLife(_msgSender());
  }

  // @dev see {IManager-requestTransfer}
  function requestTransfer(address beneficiary) external {
    if (beneficiary == address(0)) revert ZeroAddress();
    if (_inheritanceConf.proofOfLifeDurationInDays == 0) revert InheritanceNotConfigured();
    uint256 i = _findActorIndex(_msgSender(), SENTINEL);
    if (i == MAX_ACTORS) revert NotASentinel();
    if (
      _inheritanceConf.lastProofOfLife + (_inheritanceConf.proofOfLifeDurationInDays * 1 days) >
      // solhint-disable-next-line not-rely-on-time
      block.timestamp
    ) revert StillAlive();
    // the following prevents hostile beneficiaries from blocking the process not allowing them to reset the recipient
    for (i = 0; i < _inheritanceRequest.approvers.length; i++) {
      if (_msgSender() == _inheritanceRequest.approvers[i]) {
        revert RequestAlreadyApproved();
      }
    }
    if (_inheritanceRequest.beneficiary != beneficiary) {
      // a sentinel can propose a new beneficiary only after the first request expires
      if (block.timestamp - _inheritanceRequest.startedAt > 30 days) {
        delete _inheritanceRequest;
      } else revert InconsistentRecipient();
    }
    if (_inheritanceRequest.beneficiary == address(0)) {
      _inheritanceRequest.beneficiary = beneficiary;
      // solhint-disable-next-line not-rely-on-time
      _inheritanceRequest.startedAt = block.timestamp;
      _inheritanceRequest.approvers.push(_msgSender());
      emit TransferRequested(_msgSender(), beneficiary);
    } else {
      _inheritanceRequest.approvers.push(_msgSender());
      emit TransferRequestApproved(_msgSender());
    }
  }

  // @dev see {IManager-inherit}
  function inherit() external {
    // we set an expiration time in case the beneficiary cannot inherit
    // so the sentinels can propose a new beneficiary
    if (block.timestamp - _inheritanceRequest.startedAt > 60 days) {
      delete _inheritanceRequest;
    }
    if (_inheritanceRequest.beneficiary == _msgSender() && _inheritanceRequest.approvers.length >= _inheritanceConf.quorum) {
      delete _inheritanceConf;
      delete _inheritanceRequest;
      _resetActors();
      vault.managedTransfer(tokenId(), _msgSender());
      emit InheritedBy(_msgSender());
    } else revert Unauthorized();
  }

  // internal functions

  // @dev Validates the request.
  // @param scope The scope of the request.
  // @param actor The actor of the request.
  // @param status The status of the actor
  // @param timestamp The timestamp of the request.
  // @param validFor The validity of the request.
  // @param signature The signature of the request.
  function _validateRequest(
    uint256 scope,
    address actor,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) internal {
    if (timestamp == 0) {
      if (countActiveProtectors() > 0) revert NotPermittedWhenProtectorsAreActive();
    } else {
      if (timestamp == 0) revert TimestampZero();
      if (timestamp > block.timestamp || timestamp < block.timestamp - validFor) revert TimestampInvalidOrExpired();
      if (usedSignatures[keccak256(signature)]) revert SignatureAlreadyUsed();
      address signer = signatureValidator.recoverSigner(
        scope,
        owner(),
        actor,
        tokenId(),
        status,
        timestamp,
        validFor,
        signature
      );
      if (!isAProtector(signer)) revert WrongDataOrNotSignedByProtector();
      usedSignatures[keccak256(signature)] = true;
    }
  }

  // @dev Adds an actor, validating the data.
  // @param scopeString The scope of the request, i.e., the type of actor.
  // @param role_ The role of the actor.
  // @param actor The actor address.
  // @param status The status of the request.
  // @param timestamp The timestamp of the request.
  // @param validFor The validity of the request.
  // @param signature The signature of the request.
  function _setSignedActor(
    string memory scopeString,
    address actor,
    bytes32 role_,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature,
    bool actorIsProtector
  ) internal onlyTokenOwner {
    if (actor == address(0)) revert ZeroAddress();
    if (actor == _msgSender()) revert CannotBeYourself();
    _validateRequest(signatureValidator.getSupportedScope(scopeString), actor, status, timestamp, validFor, signature);
    if (!status) {
      if (timestamp != 0 && actorIsProtector && !isAProtector(actor)) revert ProtectorNotFound();
      _removeActor(actor, role_);
    } else {
      if (timestamp != 0 && actorIsProtector && isAProtector(actor)) revert ProtectorAlreadySetByYou();
      _addActor(actor, role_);
    }
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
