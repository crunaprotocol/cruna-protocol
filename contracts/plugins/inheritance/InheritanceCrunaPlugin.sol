// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IInheritanceCrunaPlugin} from "./IInheritanceCrunaPlugin.sol";
import {ICrunaPlugin, CrunaPluginBase} from "../CrunaPluginBase.sol";
import {INamed} from "../../utils/INamed.sol";
import {Actor} from "../../manager/Actor.sol";

//import {console} from "hardhat/console.sol";

contract InheritanceCrunaPlugin is ICrunaPlugin, IInheritanceCrunaPlugin, CrunaPluginBase, Actor {
  using ECDSA for bytes32;
  using Strings for uint256;

  error QuorumCannotBeZero();
  error QuorumCannotBeGreaterThanSentinels();
  error InheritanceNotConfigured();
  error StillAlive();
  error NotASentinel();
  error NotTheBeneficiary();
  error Expired();
  error BeneficiaryNotSet();
  error WaitingForBeneficiary();
  error InvalidValidity();
  error NoVoteToRetire();
  error InvalidParameters();
  error TooManySentinels();
  error CannotReceiveFunds();

  bytes4 public constant SENTINEL = bytes4(keccak256(abi.encodePacked("SENTINEL")));
  InheritanceConf internal _inheritanceConf;
  Votes internal _votes;

  receive() external payable virtual override {
    revert CannotReceiveFunds();
  }

  function requiresToManageTransfer() external pure override returns (bool) {
    return true;
  }

  function nameId() public pure virtual override returns (bytes4) {
    return bytes4(keccak256("InheritanceCrunaPlugin"));
  }

  function _isProtected() internal view virtual override returns (bool) {
    return _manager().hasProtectors();
  }

  function _isProtector(address protector) internal view virtual override returns (bool) {
    return _manager().isAProtector(protector);
  }

  // sentinels and beneficiaries
  // @dev see {IInheritanceCrunaPlugin.sol-setSentinel}
  function setSentinel(
    address sentinel,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) public virtual override onlyTokenOwner {
    if (validFor > 9_999_999) revert InvalidValidity();
    _validateAndCheckSignature(
      this.setSentinel.selector,
      owner(),
      sentinel,
      tokenAddress(),
      tokenId(),
      status ? 1 : 0,
      0,
      0,
      timestamp * 1e7 + validFor,
      signature
    );
    if (!status) {
      _removeActor(sentinel, SENTINEL);
      uint256 shares = actorCount(SENTINEL);
      if (_inheritanceConf.quorum > shares) {
        _inheritanceConf.quorum = uint8(shares);
      }
    } else {
      _addActor(sentinel, SENTINEL);
    }
    emit SentinelUpdated(_msgSender(), sentinel, status);
  }

  // @dev see {IInheritanceCrunaPlugin.sol-setSentinels}
  function setSentinels(address[] memory sentinels, bytes calldata emptySignature) external virtual override onlyTokenOwner {
    for (uint256 i; i < sentinels.length; i++) {
      setSentinel(sentinels[i], true, 0, 0, emptySignature);
    }
    if (getActors(SENTINEL).length > 11) revert TooManySentinels();
  }

  // @dev see {IInheritanceCrunaPlugin.sol-configureInheritance}
  // allow when protectors are active
  function configureInheritance(
    uint8 quorum,
    uint8 proofOfLifeDurationInWeeks,
    uint8 gracePeriodInWeeks,
    address beneficiary,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    if (validFor > 9_999_999) revert InvalidValidity();
    _validateAndCheckSignature(
      this.configureInheritance.selector,
      owner(),
      beneficiary,
      tokenAddress(),
      tokenId(),
      quorum,
      proofOfLifeDurationInWeeks,
      gracePeriodInWeeks,
      timestamp * 1e7 + validFor,
      signature
    );
    _configureInheritance(quorum, proofOfLifeDurationInWeeks, gracePeriodInWeeks, beneficiary);
  }

  function _configureInheritance(
    uint8 quorum,
    uint8 proofOfLifeDurationInWeeks,
    uint8 gracePeriodInWeeks,
    address beneficiary
  ) internal virtual {
    if (actorCount(SENTINEL) != 0 && quorum == 0) revert QuorumCannotBeZero();
    if (quorum > actorCount(SENTINEL)) revert QuorumCannotBeGreaterThanSentinels();
    if (quorum == 0 && beneficiary == address(0)) revert InvalidParameters();
    _inheritanceConf.quorum = quorum;
    _inheritanceConf.proofOfLifeDurationInWeeks = proofOfLifeDurationInWeeks;
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf.lastProofOfLife = uint32(block.timestamp);
    _inheritanceConf.gracePeriodInWeeks = gracePeriodInWeeks;
    _inheritanceConf.beneficiary = beneficiary;
    _resetNominationsAndVotes();
    emit InheritanceConfigured(_msgSender(), quorum, proofOfLifeDurationInWeeks, gracePeriodInWeeks, beneficiary);
  }

  // @dev see {IInheritanceCrunaPlugin.sol-getSentinelsAndInheritanceData}
  function getSentinelsAndInheritanceData() external view virtual override returns (address[] memory, InheritanceConf memory) {
    return (getActors(SENTINEL), _inheritanceConf);
  }

  function getVotes() external view virtual override returns (address[] memory) {
    address[] memory votes = getActors(SENTINEL);
    for (uint256 i; i < votes.length; i++) {
      votes[i] = _votes.favorites[votes[i]];
    }
    return votes;
  }

  // @dev see {IInheritanceCrunaPlugin.sol-proofOfLife}
  function proofOfLife() external virtual override onlyTokenOwner {
    if (_inheritanceConf.proofOfLifeDurationInWeeks == 0) revert InheritanceNotConfigured();
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf.lastProofOfLife = uint32(block.timestamp);
    // clean nominations and votes, if any
    _resetNominationsAndVotes();
    emit ProofOfLife(_msgSender());
  }

  function _quorumReached() internal view virtual returns (address) {
    address[] memory sentinels = getActors(SENTINEL);
    for (uint256 k = 0; k < _votes.nominations.length; k++) {
      uint256 votes = 0;
      for (uint256 i; i < sentinels.length; i++) {
        if (_votes.favorites[sentinels[i]] == _votes.nominations[k]) {
          votes++;
          if (votes == _inheritanceConf.quorum) {
            return _votes.nominations[k];
          }
        }
      }
    }
    return address(0);
  }

  function _isNominated(address beneficiary) internal view virtual returns (bool) {
    for (uint256 i; i < _votes.nominations.length; i++) {
      if (beneficiary == _votes.nominations[i]) {
        return true;
      }
    }
    return false;
  }

  function _popNominated(address beneficiary) internal virtual {
    for (uint256 i; i < _votes.nominations.length; i++) {
      if (beneficiary == _votes.nominations[i]) {
        _votes.nominations[i] = _votes.nominations[_votes.nominations.length - 1];
        _votes.nominations.pop();
        break;
      }
    }
  }

  // @dev see {IInheritanceCrunaPlugin.sol-requestTransfer}
  function requestTransfer(address beneficiary) external virtual override {
    if (_inheritanceConf.proofOfLifeDurationInWeeks == 0) revert InheritanceNotConfigured();
    if (_inheritanceConf.beneficiary != address(0) && !_isGracePeriodExpiredForBeneficiary()) revert WaitingForBeneficiary();
    _checkIfStillAlive();
    if (!_isASentinel()) revert NotASentinel();
    if (beneficiary == address(0)) {
      if (_votes.favorites[_msgSender()] == address(0)) revert NoVoteToRetire();
      else {
        _popNominated(_votes.favorites[_msgSender()]);
        delete _votes.favorites[_msgSender()];
      }
    } else if (!_isNominated(beneficiary)) {
      _votes.nominations.push(beneficiary);
    }
    //    console.log("requestTransfer");
    emit VotedForBeneficiary(_msgSender(), beneficiary);
    _votes.favorites[_msgSender()] = beneficiary;
    address winner = _quorumReached();
    if (winner == address(0)) {
      // here in case there is a previous nominated beneficiary
      delete _inheritanceConf.beneficiary;
    } else {
      emit BeneficiaryApproved(beneficiary);
      _inheritanceConf.beneficiary = winner;
      // solhint-disable-next-line not-rely-on-time
      _inheritanceConf.extendedProofOfLife = uint32(block.timestamp) - _inheritanceConf.lastProofOfLife;
      _resetNominationsAndVotes();
    }
  }

  function _resetNominationsAndVotes() internal virtual {
    if (_votes.nominations.length > 0) {
      delete _votes.nominations;
      address[] memory _sentinels = getActors(SENTINEL);
      for (uint256 i; i < _sentinels.length; i++) {
        delete _votes.favorites[_sentinels[i]];
      }
    }
  }

  function _isASentinel() internal view virtual returns (bool) {
    return actorIndex(_msgSender(), SENTINEL) != MAX_ACTORS;
  }

  function _checkIfStillAlive() internal view virtual {
    if (
      // solhint-disable-next-line not-rely-on-time
      block.timestamp - _inheritanceConf.lastProofOfLife < uint256(_inheritanceConf.proofOfLifeDurationInWeeks) * 7 days
    ) revert StillAlive();
  }

  function _isGracePeriodExpiredForBeneficiary() internal virtual returns (bool) {
    if (
      // solhint-disable-next-line not-rely-on-time
      block.timestamp - (_inheritanceConf.lastProofOfLife + _inheritanceConf.extendedProofOfLife) >
      (uint256(_inheritanceConf.proofOfLifeDurationInWeeks) + _inheritanceConf.gracePeriodInWeeks) * 7 days
    ) {
      delete _inheritanceConf.beneficiary;
      _resetNominationsAndVotes();
      return true;
    } else {
      return false;
    }
  }

  // @dev see {IInheritanceCrunaPlugin.sol-inherit}
  function inherit() external virtual override {
    if (_inheritanceConf.beneficiary == address(0)) revert BeneficiaryNotSet();
    if (_inheritanceConf.beneficiary != _msgSender()) revert NotTheBeneficiary();
    _checkIfStillAlive();
    _reset();
    _manager().managedTransfer(nameId(), _msgSender());
  }

  function reset() external override {
    if (_msgSender() != address(_manager())) revert Forbidden();
    _reset();
  }

  function _reset() internal {
    _deleteActors(SENTINEL);
    delete _inheritanceConf;
  }

  function requiresResetOnTransfer() external pure returns (bool) {
    return true;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
