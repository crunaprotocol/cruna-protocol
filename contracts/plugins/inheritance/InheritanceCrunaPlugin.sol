// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IInheritanceCrunaPlugin} from "./IInheritanceCrunaPlugin.sol";
import {ICrunaPlugin, CrunaPluginBase} from "../CrunaPluginBase.sol";

//import {console} from "hardhat/console.sol";

contract InheritanceCrunaPlugin is ICrunaPlugin, IInheritanceCrunaPlugin, CrunaPluginBase {
  using ECDSA for bytes32;
  using Strings for uint256;

  uint256 private constant _MAX_ACTORS = 16;
  /**
   * @dev It returns a bytes4 identifying a SENTINEL actor.
   */
  bytes4 private constant _SENTINEL = 0xd3eedd6d; // bytes4(keccak256("SENTINEL"))

  InheritanceConf internal _inheritanceConf;
  Votes internal _votes;

  function requiresToManageTransfer() external pure override returns (bool) {
    return true;
  }

  // sentinels and beneficiaries
  // @dev see {IInheritanceCrunaPlugin.sol-setSentinel}
  function setSentinel(
    address sentinel,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner ifMustNotBeReset {
    _setSentinel(sentinel, status, timestamp, validFor, signature);
  }

  // @dev see {IInheritanceCrunaPlugin.sol-setSentinels}
  function setSentinels(
    address[] memory sentinels,
    bytes calldata emptySignature
  ) external virtual override onlyTokenOwner ifMustNotBeReset {
    uint256 len = sentinels.length;
    for (uint256 i; i < len; ) {
      _setSentinel(sentinels[i], true, 0, 0, emptySignature);
      unchecked {
        i++;
      }
    }
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
  ) external virtual override onlyTokenOwner ifMustNotBeReset {
    if (validFor > _MAX_VALID_FOR) revert InvalidValidity();
    _validateAndCheckSignature(
      this.configureInheritance.selector,
      owner(),
      beneficiary,
      tokenAddress(),
      tokenId(),
      quorum,
      proofOfLifeDurationInWeeks,
      gracePeriodInWeeks,
      timestamp * _TIMESTAMP_MULTIPLIER + validFor,
      signature
    );
    _configureInheritance(quorum, proofOfLifeDurationInWeeks, gracePeriodInWeeks, beneficiary);
  }

  function countSentinels() external view virtual override returns (uint256) {
    if (_conf.mustBeReset == 1) return 0;
    return _actorCount(_SENTINEL);
  }

  // @dev see {IInheritanceCrunaPlugin.sol-getSentinelsAndInheritanceData}
  function getSentinelsAndInheritanceData() external view virtual override returns (address[] memory, InheritanceConf memory) {
    if (_conf.mustBeReset == 1) return (new address[](0), InheritanceConf(address(0), 0, 0, 0, 0, 0));
    return (_getActors(_SENTINEL), _inheritanceConf);
  }

  function getVotes() external view virtual override returns (address[] memory) {
    address[] memory votes = _conf.mustBeReset == 1 ? new address[](0) : _getActors(_SENTINEL);
    uint256 len = votes.length;
    for (uint256 i; i < len; ) {
      votes[i] = _votes.favorites[votes[i]];
      unchecked {
        i++;
      }
    }
    return votes;
  }

  // @dev see {IInheritanceCrunaPlugin.sol-proofOfLife}
  function proofOfLife() external virtual override onlyTokenOwner ifMustNotBeReset {
    if (0 == _inheritanceConf.proofOfLifeDurationInWeeks) revert InheritanceNotConfigured();
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf.lastProofOfLife = uint32(block.timestamp);
    // clean nominations and votes, if any
    _resetNominationsAndVotes();
    emit ProofOfLife(_msgSender());
  }

  // @dev see {IInheritanceCrunaPlugin.sol-requestTransfer}
  function requestTransfer(address beneficiary) external virtual override ifMustNotBeReset {
    if (0 == _inheritanceConf.proofOfLifeDurationInWeeks) revert InheritanceNotConfigured();
    if (_inheritanceConf.beneficiary != address(0))
      if (!_isGracePeriodExpiredForBeneficiary()) revert WaitingForBeneficiary();
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

  // @dev see {IInheritanceCrunaPlugin.sol-inherit}
  function inherit() external virtual override ifMustNotBeReset {
    if (_inheritanceConf.beneficiary == address(0)) revert BeneficiaryNotSet();
    if (_inheritanceConf.beneficiary != _msgSender()) revert NotTheBeneficiary();
    _checkIfStillAlive();
    _reset();
    _conf.manager.managedTransfer(_nameId(), _msgSender());
  }

  function reset() external override onlyManager {
    _reset();
  }

  function requiresResetOnTransfer() external pure returns (bool) {
    return true;
  }

  function _nameId() internal pure virtual override returns (bytes4) {
    return bytes4(keccak256("InheritanceCrunaPlugin"));
  }

  function _isProtected() internal view virtual override returns (bool) {
    return _conf.manager.hasProtectors();
  }

  function _isProtector(address protector) internal view virtual override returns (bool) {
    return _conf.manager.isProtector(protector);
  }

  function _setSentinel(
    address sentinel,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) internal virtual onlyTokenOwner ifMustNotBeReset {
    if (validFor > _MAX_VALID_FOR) revert InvalidValidity();
    _validateAndCheckSignature(
      this.setSentinel.selector,
      owner(),
      sentinel,
      tokenAddress(),
      tokenId(),
      status ? 1 : 0,
      0,
      0,
      timestamp * _TIMESTAMP_MULTIPLIER + validFor,
      signature
    );
    if (!status) {
      _removeActor(sentinel, _SENTINEL);
      uint256 shares = _actorCount(_SENTINEL);
      if (_inheritanceConf.quorum > shares) {
        _inheritanceConf.quorum = uint8(shares);
      }
    } else {
      // will revert if more than 16 sentinels
      _addActor(sentinel, _SENTINEL);
    }
    emit SentinelUpdated(_msgSender(), sentinel, status);
  }

  function _configureInheritance(
    uint8 quorum,
    uint8 proofOfLifeDurationInWeeks,
    uint8 gracePeriodInWeeks,
    address beneficiary
  ) internal virtual {
    if (0 != _actorCount(_SENTINEL))
      if (0 == quorum) revert QuorumCannotBeZero();
    if (quorum > _actorCount(_SENTINEL)) revert QuorumCannotBeGreaterThanSentinels();
    if (0 == quorum)
      if (beneficiary == address(0)) revert InvalidParameters();
    _inheritanceConf.quorum = quorum;
    _inheritanceConf.proofOfLifeDurationInWeeks = proofOfLifeDurationInWeeks;
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf.lastProofOfLife = uint32(block.timestamp);
    _inheritanceConf.gracePeriodInWeeks = gracePeriodInWeeks;
    _inheritanceConf.beneficiary = beneficiary;
    _resetNominationsAndVotes();
    emit InheritanceConfigured(_msgSender(), quorum, proofOfLifeDurationInWeeks, gracePeriodInWeeks, beneficiary);
  }

  function _quorumReached() internal view virtual returns (address) {
    address[] memory sentinels = _getActors(_SENTINEL);
    uint256 len = _votes.nominations.length;
    for (uint256 k; k < len; ) {
      unchecked {
        uint256 votes;
        uint256 len2 = sentinels.length;
        for (uint256 i; i < len2; i++) {
          if (_votes.favorites[sentinels[i]] == _votes.nominations[k]) {
            votes++;
            if (votes == _inheritanceConf.quorum) {
              return _votes.nominations[k];
            }
          }
        }
        k++;
      }
    }
    return address(0);
  }

  function _isNominated(address beneficiary) internal view virtual returns (bool) {
    uint256 len = _votes.nominations.length;
    for (uint256 i; i < len; ) {
      if (beneficiary == _votes.nominations[i]) {
        return true;
      }
      unchecked {
        i++;
      }
    }
    return false;
  }

  function _popNominated(address beneficiary) internal virtual {
    uint256 len = _votes.nominations.length;
    for (uint256 i; i < len; ) {
      unchecked {
        if (beneficiary == _votes.nominations[i]) {
          _votes.nominations[i] = _votes.nominations[_votes.nominations.length - 1];
          _votes.nominations.pop();
          break;
        }
        i++;
      }
    }
  }

  function _resetNominationsAndVotes() internal virtual {
    if (_votes.nominations.length != 0) {
      delete _votes.nominations;
      address[] memory _sentinels = _getActors(_SENTINEL);
      uint256 len = _sentinels.length;
      for (uint256 i; i < len; ) {
        delete _votes.favorites[_sentinels[i]];
        unchecked {
          i++;
        }
      }
    }
  }

  function _isASentinel() internal view virtual returns (bool) {
    return _actorIndex(_msgSender(), _SENTINEL) != _MAX_ACTORS;
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
    }
    return false;
  }

  function _reset() internal {
    delete _actors[_SENTINEL];
    delete _inheritanceConf;
    delete _votes;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
