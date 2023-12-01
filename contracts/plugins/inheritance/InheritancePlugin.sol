// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Manager} from "../../manager/Manager.sol";
import {IInheritancePlugin} from "./IInheritancePlugin.sol";
import {Versioned} from "../../utils/Versioned.sol";
import {IPlugin} from "../IPlugin.sol";
import {Guardian, ManagerBase} from "../../manager/ManagerBase.sol";

//import {console} from "hardhat/console.sol";

contract InheritancePlugin is IPlugin, IInheritancePlugin, Versioned, ManagerBase {
  using ECDSA for bytes32;
  using Strings for uint256;

  error ZeroAddress();
  error Forbidden();
  error NotPermittedWhenProtectorsAreActive();
  error QuorumCannotBeZero();
  error QuorumCannotBeGreaterThanSentinels();
  error InheritanceNotConfigured();
  error StillAlive();
  error InconsistentRecipient();
  error NotASentinel();
  error RequestAlreadyApproved();
  error Unauthorized();

  bytes32 public constant SENTINEL = keccak256(abi.encodePacked("SENTINEL"));

  Manager public manager;

  InheritanceRequest internal _inheritanceRequest;
  InheritanceConf internal _inheritanceConf;

  // @dev see {IInheritancePlugin.sol-init}
  // this must be execute immediately after the deployment
  function init(address guardian_) external virtual {
    _nameHash = keccak256("InheritancePlugin");
    if (msg.sender != tokenAddress()) revert Forbidden();
    guardian = Guardian(guardian_);
    manager = Manager(msg.sender);
  }

  function pluginRoles() external pure virtual returns (bytes32[] memory) {
    bytes32[] memory roles = new bytes32[](1);
    roles[0] = keccak256("SENTINEL");
    return roles;
  }

  // sentinels and beneficiaries
  // @dev see {IInheritancePlugin.sol-setSentinel}
  function setSentinel(
    address sentinel,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) public virtual override onlyTokenOwner {
    manager.setSignedActor("SENTINEL", sentinel, SENTINEL, status, timestamp, validFor, signature);
    emit SentinelUpdated(_msgSender(), sentinel, status);
  }

  // @dev see {IInheritancePlugin.sol-setSentinels}
  function setSentinels(address[] memory sentinels, bytes calldata emptySignature) external virtual override onlyTokenOwner {
    for (uint256 i = 0; i < sentinels.length; i++) {
      setSentinel(sentinels[i], true, 0, 0, emptySignature);
    }
  }

  // @dev see {IInheritancePlugin.sol-configureInheritance}
  // allow when protectors are active
  function configureInheritance(uint256 quorum, uint256 proofOfLifeDurationInDays) external virtual override onlyTokenOwner {
    if (manager.countActiveProtectors() > 0) revert NotPermittedWhenProtectorsAreActive();
    if (quorum == 0) revert QuorumCannotBeZero();
    if (quorum > manager.actorCount(SENTINEL)) revert QuorumCannotBeGreaterThanSentinels();
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf = InheritanceConf(quorum, proofOfLifeDurationInDays, block.timestamp);
    delete _inheritanceRequest;
    emit InheritanceConfigured(_msgSender(), quorum, proofOfLifeDurationInDays);
  }

  // @dev see {IInheritancePlugin.sol-getSentinelsAndInheritanceData}
  function getSentinelsAndInheritanceData()
    external
    view
    virtual
    override
    returns (address[] memory, InheritanceConf memory, InheritanceRequest memory)
  {
    return (manager.getActors(SENTINEL), _inheritanceConf, _inheritanceRequest);
  }

  // @dev see {IInheritancePlugin.sol-proofOfLife}
  function proofOfLife() external virtual override onlyTokenOwner {
    if (_inheritanceConf.proofOfLifeDurationInDays == 0) revert InheritanceNotConfigured();
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf.lastProofOfLife = block.timestamp;
    delete _inheritanceRequest;
    emit ProofOfLife(_msgSender());
  }

  // @dev see {IInheritancePlugin.sol-requestTransfer}
  function requestTransfer(address beneficiary) external virtual override {
    if (beneficiary == address(0)) revert ZeroAddress();
    if (_inheritanceConf.proofOfLifeDurationInDays == 0) revert InheritanceNotConfigured();
    uint256 i = manager.actorIndex(_msgSender(), SENTINEL);
    if (i == manager.MAX_ACTORS()) revert NotASentinel();
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

  // @dev see {IInheritancePlugin.sol-inherit}
  function inherit() external virtual override {
    // we set an expiration time in case the beneficiary cannot inherit
    // so the sentinels can propose a new beneficiary
    if (block.timestamp - _inheritanceRequest.startedAt > 60 days) {
      delete _inheritanceRequest;
    }
    if (_inheritanceRequest.beneficiary == _msgSender() && _inheritanceRequest.approvers.length >= _inheritanceConf.quorum) {
      delete _inheritanceConf;
      delete _inheritanceRequest;
      manager.managedTransfer(tokenId(), _msgSender());
      emit InheritedBy(_msgSender());
    } else revert Unauthorized();
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
