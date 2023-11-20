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
import {Actor, IActor} from "./Actor.sol";
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
  error NotExpiredYet();
  error InconsistentRecipient();
  error NotASentinel();
  error RequestAlreadyApproved();
  error Unauthorized();
  error NotAnActiveProtector();
  error CannotBeYourself();
  error NotTheFirstProtector();
  error FirstProtectorNotFound();

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

  function tokenAddress() public view returns (address) {
    (, address tokenContract_, ) = token();
    return tokenContract_;
  }

  function tokenId() public view returns (uint256) {
    (, , uint256 tokenId_) = token();
    return tokenId_;
  }

  // TODO unnecessary if we do not implement the assets distributor
  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    // This contract is not supposed to own vaults itself
    if (vault.balanceOf(address(this)) > 0) revert Errors.OwnershipCycle();
    return this.onERC721Received.selector;
  }

  // actors

  function countActiveProtectors() public view override returns (uint256) {
    return _countActiveActorsByRole(PROTECTOR);
  }

  function findProtector(address protector_) public view override returns (uint256, Status) {
    (uint256 i, IActor.Actor storage actor) = _getActor(protector_, PROTECTOR);
    return (i, actor.status);
  }

  function isAProtector(address protector_) public view returns (bool) {
    Status status = _actorStatus(protector_, PROTECTOR);
    return status == Status.ACTIVE;
  }

  function listProtectors() public view override returns (address[] memory) {
    return _listActiveActors(PROTECTOR);
  }

  function setProtector(
    address protector_,
    bool active,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    _setSignedActor("PROTECTOR", protector_, PROTECTOR, active ? 1 : 0, timestamp, validFor, signature, true);
    emit ProtectorUpdated(_msgSender(), protector_, active);
  }

  function getProtectors() external view override returns (IActor.Actor[] memory) {
    return _getActors(PROTECTOR);
  }

  // safe recipients

  function setSafeRecipient(
    address recipient,
    Level level,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external override onlyTokenOwner {
    _setSignedActor("SAFE_RECIPIENT", recipient, SAFE_RECIPIENT, uint256(level), timestamp, validFor, signature, false);
    emit SafeRecipientUpdated(_msgSender(), recipient, level);
  }

  function safeRecipientLevel(address recipient) public view override returns (Level) {
    (, IActor.Actor memory actor) = _getActor(recipient, SAFE_RECIPIENT);
    return actor.level;
  }

  function getSafeRecipients() external view override returns (IActor.Actor[] memory) {
    return _getActors(SAFE_RECIPIENT);
  }

  // beneficiaries

  function setSentinel(
    address sentinel,
    Status status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external override onlyTokenOwner {
    _setSignedActor("SENTINEL", sentinel, SENTINEL, uint256(status), timestamp, validFor, signature, false);
    emit SentinelUpdated(_msgSender(), sentinel, status);
  }

  // allow when protectors are active
  function configureInheritance(uint256 quorum, uint256 proofOfLifeDurationInDays) external onlyTokenOwner {
    if (countActiveProtectors() > 0) revert NotPermittedWhenProtectorsAreActive();
    if (quorum == 0) revert QuorumCannotBeZero();
    if (quorum > _countActiveActorsByRole(SENTINEL)) revert QuorumCannotBeGreaterThanSentinels();
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf = InheritanceConf(quorum, proofOfLifeDurationInDays, block.timestamp);
    delete _inheritanceRequest;
  }

  function getSentinels() external view returns (IActor.Actor[] memory, InheritanceConf memory) {
    return (_getActors(SENTINEL), _inheritanceConf);
  }

  function proofOfLife() external onlyTokenOwner {
    if (_inheritanceConf.proofOfLifeDurationInDays == 0) revert InheritanceNotConfigured();
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf.lastProofOfLife = block.timestamp;
    delete _inheritanceRequest;
  }

  function requestTransfer(address beneficiary) external {
    if (beneficiary == address(0)) revert ZeroAddress();
    if (_inheritanceConf.proofOfLifeDurationInDays == 0) revert InheritanceNotConfigured();
    (, IActor.Actor storage actor) = _getActor(_msgSender(), SENTINEL);
    if (actor.status == Status.UNSET) revert NotASentinel();
    if (
      _inheritanceConf.lastProofOfLife + (_inheritanceConf.proofOfLifeDurationInDays * 1 hours) >
      // solhint-disable-next-line not-rely-on-time
      block.timestamp
    ) revert NotExpiredYet();
    // the following prevents hostile beneficiaries from blocking the process not allowing them to reset the recipient
    if (_hasApproved()) revert RequestAlreadyApproved();
    // a sentinel is proposing a new recipient
    if (_inheritanceRequest.recipient != beneficiary) {
      // solhint-disable-next-line not-rely-on-time
      if (block.timestamp - _inheritanceRequest.startedAt > 30 days) {
        // reset the request
        delete _inheritanceRequest;
      } else revert InconsistentRecipient();
    }
    if (_inheritanceRequest.recipient == address(0)) {
      _inheritanceRequest.recipient = beneficiary;
      // solhint-disable-next-line not-rely-on-time
      _inheritanceRequest.startedAt = block.timestamp;
      _inheritanceRequest.approvers.push(_msgSender());
    } else {
      _inheritanceRequest.approvers.push(_msgSender());
    }
  }

  // TODO add a deadline after a while a new beneficiary can be set
  function inherit() external {
    if (_inheritanceRequest.recipient == _msgSender() && _inheritanceRequest.approvers.length >= _inheritanceConf.quorum) {
      vault.managedTransfer(tokenId(), _msgSender());
      emit Inherited(tokenAddress(), tokenId(), owner(), _msgSender());
      delete _inheritanceRequest;
    } else revert Unauthorized();
  }

  // internal functions

  function _validateRequest(
    uint256 scope,
    address actor,
    uint256 extraValue,
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
        extraValue,
        timestamp,
        validFor,
        signature
      );
      if (!isAProtector(signer)) revert WrongDataOrNotSignedByProtector();
      usedSignatures[keccak256(signature)] = true;
    }
  }

  function _setSignedActor(
    string memory scopeString,
    address actor,
    bytes32 role_,
    uint256 extraValue,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature,
    bool actorIsProtector
  ) internal onlyTokenOwner {
    uint256 scope = signatureValidator.getSupportedScope(scopeString);
    if (actor == address(0)) revert ZeroAddress();
    if (actor == _msgSender()) revert CannotBeYourself();
    _validateRequest(scope, actor, extraValue, timestamp, validFor, signature);
    if (extraValue == 0) {
      if (timestamp != 0 && actorIsProtector && !isAProtector(actor)) revert ProtectorNotFound();
      _removeActor(actor, role_);
    } else {
      if (timestamp != 0 && actorIsProtector && isAProtector(actor)) revert ProtectorAlreadySetByYou();
      _addActor(actor, role_, Status.ACTIVE, Level(extraValue));
    }
  }

  function _hasApproved() internal view returns (bool) {
    for (uint256 i = 0; i < _inheritanceRequest.approvers.length; i++) {
      if (_msgSender() == _inheritanceRequest.approvers[i]) {
        return true;
      }
    }
    return false;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}
