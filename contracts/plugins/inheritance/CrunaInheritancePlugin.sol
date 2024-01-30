// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {CrunaManager} from "../../manager/CrunaManager.sol";
import {ICrunaInheritancePlugin} from "./ICrunaInheritancePlugin.sol";
import {IPlugin} from "../IPlugin.sol";
import {IVault, CrunaManagerBase} from "../../manager/CrunaManagerBase.sol";
import {Actor} from "../../manager/Actor.sol";
import {SignatureValidator} from "../../utils/SignatureValidator.sol";

//import {console} from "hardhat/console.sol";

contract CrunaInheritancePlugin is IPlugin, ICrunaInheritancePlugin, CrunaManagerBase, Actor, SignatureValidator {
  using ECDSA for bytes32;
  using Strings for uint256;

  error Forbidden();
  error NotPermittedWhenProtectorsAreActive();
  error QuorumCannotBeZero();
  error QuorumCannotBeGreaterThanSentinels();
  error InheritanceNotConfigured();
  error StillAlive();
  error NotASentinel();
  error RequestAlreadyApproved();
  error NotTheBeneficiary();
  error QuorumNotReached();
  error Expired();
  error BeneficiaryNotSet();
  error WaitingForBeneficiary();
  error NotExpiredYet();
  error QuorumAlreadyReached();
  error WrongDataOrNotSignedByProtector();
  error SignatureAlreadyUsed();

  mapping(bytes32 => bool) public usedSignatures;
  bytes4 public constant SENTINEL = bytes4(keccak256(abi.encodePacked("SENTINEL")));
  CrunaManager public manager;
  InheritanceConf internal _inheritanceConf;

  // @dev see {ICrunaInheritancePlugin.sol-init}
  // this must be execute immediately after the deployment
  function init() external virtual override {
    // Notice that the manager pretends to be an NFT
    // so tokenAddress() returns the manager address
    if (_msgSender() != tokenAddress()) revert Forbidden();
    manager = CrunaManager(_msgSender());
  }

  function requiresToManageTransfer() external pure override returns (bool) {
    return true;
  }

  function nameId() public virtual override returns (bytes4) {
    return bytes4(keccak256("CrunaInheritancePlugin"));
  }

  function vault() public view virtual override returns (IVault) {
    return IVault(manager.tokenAddress());
  }

  // sentinels and beneficiaries
  // @dev see {ICrunaInheritancePlugin.sol.sol-setSentinel}
  function setSentinel(
    address sentinel,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) public virtual override onlyTokenOwner {
    _validateAndCheckSignature(
      this.setSentinel.selector,
      sentinel,
      status ? 1 : 0,
      0,
      0,
      timestamp * 1e6 + validFor,
      signature
    );
    if (!status) {
      _removeActor(sentinel, SENTINEL);
      uint256 shares = actorCount(SENTINEL);
      if (_inheritanceConf.quorum > shares) {
        _inheritanceConf.quorum = uint16(shares);
      }
    } else {
      _addActor(sentinel, SENTINEL);
    }
    emit SentinelUpdated(_msgSender(), sentinel, status);
  }

  // @dev see {ICrunaInheritancePlugin.sol-setSentinels}
  function setSentinels(address[] memory sentinels, bytes calldata emptySignature) external virtual override onlyTokenOwner {
    for (uint256 i = 0; i < sentinels.length; i++) {
      setSentinel(sentinels[i], true, 0, 0, emptySignature);
    }
  }

  // @dev see {ICrunaInheritancePlugin.sol.sol-configureInheritance}
  // allow when protectors are active
  function configureInheritance(
    uint256 quorum,
    uint256 proofOfLifeDurationInDays,
    uint256 gracePeriod,
    address beneficiary,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    _validateAndCheckSignature(
      this.configureInheritance.selector,
      beneficiary,
      quorum,
      proofOfLifeDurationInDays,
      gracePeriod,
      timestamp * 1e6 + validFor,
      signature
    );
    _configureInheritance(uint16(quorum), uint16(proofOfLifeDurationInDays), uint16(gracePeriod), beneficiary);
  }

  function _configureInheritance(
    uint16 quorum,
    uint16 proofOfLifeDurationInDays,
    uint16 gracePeriod,
    address beneficiary
  ) internal virtual {
    if (actorCount(SENTINEL) > 0 && quorum == 0) revert QuorumCannotBeZero();
    if (quorum > actorCount(SENTINEL)) revert QuorumCannotBeGreaterThanSentinels();
    if (quorum == 0 && beneficiary == address(0)) revert ZeroAddress();
    _inheritanceConf.quorum = quorum;
    _inheritanceConf.proofOfLifeDurationInDays = proofOfLifeDurationInDays;
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf.lastProofOfLife = uint32(block.timestamp);
    _inheritanceConf.gracePeriod = gracePeriod;
    _inheritanceConf.beneficiary = beneficiary;
    _inheritanceConf.requestUpdatedAt = 0;
    if (beneficiary != address(0)) {
      _inheritanceConf.waitForGracePeriod = true;
    }
    delete _inheritanceConf.approvers;
    emit InheritanceConfigured(_msgSender(), quorum, proofOfLifeDurationInDays, gracePeriod, beneficiary);
  }

  // @dev see {ICrunaInheritancePlugin.sol-getSentinelsAndInheritanceData}
  function getSentinelsAndInheritanceData() external view virtual override returns (address[] memory, InheritanceConf memory) {
    return (getActors(SENTINEL), _inheritanceConf);
  }

  // @dev see {ICrunaInheritancePlugin.sol.sol-proofOfLife}
  function proofOfLife() external virtual override onlyTokenOwner {
    if (_inheritanceConf.proofOfLifeDurationInDays == 0) revert InheritanceNotConfigured();
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf.lastProofOfLife = uint32(block.timestamp);
    if (_inheritanceConf.requestUpdatedAt > 0) {
      // it is not the beneficiary nominated by the owner
      delete _inheritanceConf.beneficiary;
    }
    delete _inheritanceConf.approvers;
    delete _inheritanceConf.requestUpdatedAt;
    emit ProofOfLife(_msgSender());
  }

  // @dev see {ICrunaInheritancePlugin.sol.sol-requestTransfer}
  function requestTransfer(address beneficiary) external virtual override {
    if (beneficiary == address(0)) revert ZeroAddress();
    if (_inheritanceConf.proofOfLifeDurationInDays == 0) revert InheritanceNotConfigured();
    _checkIfStillAlive();
    if (!_isASentinel()) revert NotASentinel();
    if (_inheritanceConf.waitForGracePeriod && !_isGracePeriodExpiredForBeneficiary()) revert WaitingForBeneficiary();
    // the following prevents hostile beneficiaries from blocking the process not allowing
    // them to reset the beneficiary
    for (uint256 i = 0; i < _inheritanceConf.approvers.length; i++) {
      if (_msgSender() == _inheritanceConf.approvers[i]) {
        revert RequestAlreadyApproved();
      }
    }
    if (_inheritanceConf.beneficiary != beneficiary) {
      // a different sentinel can propose a new beneficiary only after the first request expires
      if (_isGracePeriodExpiredAfterStart()) {
        delete _inheritanceConf.beneficiary;
        delete _inheritanceConf.approvers;
      } else revert NotExpiredYet();
    }
    if (_inheritanceConf.approvers.length == _inheritanceConf.quorum) revert QuorumAlreadyReached();
    if (_inheritanceConf.beneficiary == address(0)) {
      _inheritanceConf.beneficiary = beneficiary;
      emit TransferRequested(_msgSender(), beneficiary);
    } else {
      emit TransferRequestApproved(_msgSender());
    }
    _inheritanceConf.approvers.push(_msgSender());
    // updating all the time, gives more time to the beneficiary to inherit
    _inheritanceConf.requestUpdatedAt = uint32(block.timestamp);
  }

  function _isASentinel() internal view virtual returns (bool) {
    return actorIndex(_msgSender(), SENTINEL) != MAX_ACTORS;
  }

  function _checkIfStillAlive() internal view virtual {
    if (
      // solhint-disable-next-line not-rely-on-time
      block.timestamp - _inheritanceConf.lastProofOfLife < _inheritanceConf.proofOfLifeDurationInDays * 1 days
    ) revert StillAlive();
  }

  function _isGracePeriodExpiredForBeneficiary() internal virtual returns (bool) {
    if (
      // solhint-disable-next-line not-rely-on-time
      block.timestamp - _inheritanceConf.lastProofOfLife >
      (_inheritanceConf.proofOfLifeDurationInDays + _inheritanceConf.gracePeriod) * 1 days
    ) {
      delete _inheritanceConf.beneficiary;
      delete _inheritanceConf.waitForGracePeriod;
      return true;
    } else return false;
  }

  function _isGracePeriodExpiredAfterStart() internal view virtual returns (bool) {
    return block.timestamp - _inheritanceConf.requestUpdatedAt > _inheritanceConf.gracePeriod * 1 days;
  }

  // @dev see {ICrunaInheritancePlugin.sol-inherit}
  function inherit() external virtual override {
    _checkIfStillAlive();
    if (_inheritanceConf.beneficiary == address(0)) revert BeneficiaryNotSet();
    if (_inheritanceConf.beneficiary != _msgSender()) revert NotTheBeneficiary();
    if (_inheritanceConf.waitForGracePeriod) {
      if (actorCount(SENTINEL) > 0 && _isGracePeriodExpiredForBeneficiary()) revert Expired();
    } else {
      if (_inheritanceConf.approvers.length < _inheritanceConf.quorum) revert QuorumNotReached();
      // The sentinels nominated a beneficiary
      // we set an expiration time in case the beneficiary cannot inherit
      // so the sentinels can propose a new beneficiary
      if (_isGracePeriodExpiredAfterStart()) revert Expired();
    }
    _reset();
    manager.managedTransfer(nameId(), tokenId(), _msgSender());
  }

  function reset() external override {
    if (_msgSender() != address(manager)) revert Forbidden();
    _reset();
  }

  function _reset() internal {
    _deleteActors(SENTINEL);
    delete _inheritanceConf;
  }

  // @dev Validates the request.
  // @param _functionSelector The function selector of the request.
  // @param target The target of the request.
  // @param extra The first extra param
  // @param extra2 The second extra param
  // @param extra3 The third extra param
  // @param timeValidation A combination of timestamp and validity of the signature.
  // @param signature The signature of the request.
  function _validateAndCheckSignature(
    bytes4 _functionSelector,
    address target,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
    uint256 timeValidation,
    bytes calldata signature
  ) internal virtual {
    if (timeValidation < 1e6) {
      if (manager.countActiveProtectors() > 0) revert NotPermittedWhenProtectorsAreActive();
    } else {
      if (usedSignatures[keccak256(signature)]) revert SignatureAlreadyUsed();
      usedSignatures[keccak256(signature)] = true;
      address signer = recoverSigner(
        _functionSelector,
        owner(),
        target,
        manager.tokenAddress(),
        manager.tokenId(),
        extra,
        extra2,
        extra3,
        timeValidation,
        signature
      );
      if (!manager.isAProtector(signer)) revert WrongDataOrNotSignedByProtector();
    }
  }

  function requiresResetOnTransfer() external pure returns (bool) {
    return true;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
