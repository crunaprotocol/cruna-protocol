// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {IInheritanceCrunaPlugin} from "./IInheritanceCrunaPlugin.sol";
import {ICrunaManagedService} from "../ICrunaManagedService.sol";
import {CrunaManagedService} from "../CrunaManagedService.sol";
import {GuardianInstance} from "../../libs/GuardianInstance.sol";

interface IManagedService {
  function requiredManagerVersion() external pure returns (uint256);
  function nameId() external pure returns (bytes4);
  function version() external pure returns (uint256);
}

/**
 * @title InheritanceCrunaPlugin
 * @notice This contract manages inheritance
 */
contract InheritanceCrunaPlugin is
  ICrunaManagedService,
  IInheritanceCrunaPlugin,
  GuardianInstance,
  Context,
  CrunaManagedService,
  ReentrancyGuard
{
  using ECDSA for bytes32;
  using Strings for uint256;

  /**
   * @notice Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @notice The maximum number of actors that can be set
   */
  uint256 private constant _MAX_ACTORS = 16;

  /**
   * @notice It returns a bytes4 identifying a SENTINEL actor.
   */
  bytes4 private constant _SENTINEL = 0xd3eedd6d; // bytes4(keccak256("SENTINEL"))

  /**
   * @notice The object storing the inheritance configuration
   */
  InheritanceConf internal _inheritanceConf;

  /**
   * @notice The object storing the votes
   */
  Votes internal _votes;

  /// @dev see {ICrunaManagedService.sol-requiresToManageTransfer}
  function requiresToManageTransfer() external pure override(CrunaManagedService, ICrunaManagedService) returns (bool) {
    return true;
  }

  /**
   * @notice Set a sentinel for the token
   * @param sentinel The sentinel address
   * @param status True to activate, false to deactivate
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the tokensOwner
   */
  function setSentinel(
    address sentinel,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner ifMustNotBeReset {
    _setSentinel(sentinel, status, timestamp, validFor, signature);
  }

  /**
   * @notice Set a list of sentinels for the token
   * It is a convenience function to set multiple sentinels at once, but it
   * works only if no protectors have been set up. Useful for initial settings.
   * @param sentinels The sentinel addresses
   * @param emptySignature The signature of the tokensOwner
   */
  function setSentinels(
    address[] calldata sentinels,
    bytes calldata emptySignature
  ) external virtual override onlyTokenOwner ifMustNotBeReset {
    uint256 len = sentinels.length;
    for (uint256 i; i < len; ) {
      // Notice that this will work only if no protector has been set
      _setSentinel(sentinels[i], true, 0, 0, emptySignature);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Configures an inheritance
   * Some parameters are optional depending on the scenario.
   * There are three scenarios:
   *
   * - The user sets a beneficiary. The beneficiary can inherit the NFT as soon as a Proof-of-Life is missed.
   * - The user sets more than a single sentinel. The sentinels propose a beneficiary, and when the quorum is reached, the beneficiary can inherit the NFT.
   * - The user sets a beneficiary and some sentinels. In this case, the beneficiary has a grace period to inherit the NFT. If after that grace period the beneficiary has not inherited the NFT, the sentinels can propose a new beneficiary.
   *
   * @param quorum The number of sentinels required to approve a request
   * @param proofOfLifeDurationInWeeks The duration of the Proof-of-Live, i.e., the number
   * of days after which the sentinels can start the process to inherit the token if the
   * owner does not prove to be alive
   * @param gracePeriodInWeeks The grace period in weeks
   * @param beneficiary The beneficiary address
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the tokensOwner
   */
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

  /**
   * @notice Return the number of sentinels
   */
  function countSentinels() external view virtual override returns (uint256) {
    if (_conf.mustBeReset == 1) return 0;
    return _actorCount(_SENTINEL);
  }

  /**
   * @notice Return all the sentinels and the inheritance data
   */
  function getSentinelsAndInheritanceData() external view virtual override returns (address[] memory, InheritanceConf memory) {
    if (_conf.mustBeReset == 1) return (new address[](0), InheritanceConf(address(0), 0, 0, 0, 0, 0));
    return (_getActors(_SENTINEL), _inheritanceConf);
  }

  /**
   * @notice Return all the votes
   */
  function getVotes() external view virtual override returns (address[] memory) {
    address[] memory votes = _conf.mustBeReset == 1 ? new address[](0) : _getActors(_SENTINEL);
    uint256 len = votes.length;
    for (uint256 i; i < len; ) {
      votes[i] = _votes.favorites[votes[i]];
      unchecked {
        ++i;
      }
    }
    return votes;
  }

  /**
   * @notice allows the user to trigger a Proof-of-Live
   */
  function proofOfLife() external virtual override onlyTokenOwner ifMustNotBeReset {
    if (0 == _inheritanceConf.proofOfLifeDurationInWeeks) revert InheritanceNotConfigured();
    // solhint-disable-next-line not-rely-on-time
    _inheritanceConf.lastProofOfLife = uint32(block.timestamp);
    // clean nominations and votes, if any
    _resetNominationsAndVotes();
    emit ProofOfLife(_msgSender());
  }

  /**
   * @notice Allows the sentinels to nominate a beneficiary
   * @param beneficiary The beneficiary address
   * If the beneficiary is address(0), the vote is to retire a previously voted beneficiary
   */
  function voteForBeneficiary(address beneficiary) external virtual override ifMustNotBeReset {
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

  /**
   * @notice Allows the beneficiary to inherit the token
   */
  function inherit() external virtual override ifMustNotBeReset {
    if (_inheritanceConf.beneficiary == address(0)) revert BeneficiaryNotSet();
    if (_inheritanceConf.beneficiary != _msgSender()) revert NotTheBeneficiary();
    _checkIfStillAlive();
    _resetService();
    _conf.manager.managedTransfer(_serviceKey(), _msgSender());
  }

  /// @dev see {ICrunaManagedService.sol-reset}
  function resetService() external payable override(CrunaManagedService, ICrunaManagedService) {
    if (_msgSender() != address(_conf.manager)) revert Forbidden();
    delete _conf.mustBeReset;
    _resetService();
  }

  function requiresResetOnTransfer() external pure override(CrunaManagedService, ICrunaManagedService) returns (bool) {
    return true;
  }

  /**
   * @notice Upgrades the implementation of the plugin
   * @param implementation_ The new implementation
   */
  function upgrade(address implementation_) external virtual nonReentrant {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    if (implementation_ == address(0)) revert ZeroAddress();
    // If current implementation is trusted, the new one must be trusted too
    if (_crunaGuardian().trusted(implementation()))
      if (!_crunaGuardian().trusted(implementation_)) revert UntrustedImplementation(implementation_);
    IManagedService impl = IManagedService(implementation_);
    uint256 version_ = impl.version();
    if (impl.nameId() != bytes4(keccak256("InheritanceCrunaPlugin"))) revert NotTheRightPlugin();
    if (version_ <= _version()) revert InvalidVersion(_version(), version_);
    uint256 requiredVersion = impl.requiredManagerVersion();
    if (_conf.manager.version() < requiredVersion) revert PluginRequiresUpdatedManager(requiredVersion);
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  // Internal functions

  function _onBeforeInit(bytes memory data) internal override {
    // do nothing
  }

  function _version() internal pure virtual override returns (uint256) {
    return 1_001_000;
  }

  function _nameId() internal pure virtual override returns (bytes4) {
    return bytes4(keccak256("InheritanceCrunaPlugin"));
  }

  /**
   * @notice It sets a sentinel
   * @param sentinel The sentinel address
   * @param status True if the sentinel is active, false if it is not
   * @param timestamp The timestamp
   * @param validFor The validity of the signature
   * @param signature The signature
   */
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
    if (status) {
      // will revert if more than 16 sentinels
      _addActor(sentinel, _SENTINEL);
    } else {
      _removeActor(sentinel, _SENTINEL);
      uint256 shares = _actorCount(_SENTINEL);
      if (_inheritanceConf.quorum > shares) {
        _inheritanceConf.quorum = uint8(shares);
      }
    }
    emit SentinelUpdated(_msgSender(), sentinel, status);
  }

  /**
   * @notice It configures inheritance
   * @param quorum The quorum
   * @param proofOfLifeDurationInWeeks The proof of life duration in weeks
   * @param gracePeriodInWeeks The grace period in weeks
   * @param beneficiary The beneficiary
   */
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

  /**
   * @notice Checks if the quorum has been reached
   * @return The beneficiary if the quorum has been reached, address(0) otherwise
   */
  function _quorumReached() internal view virtual returns (address) {
    address[] memory sentinels = _getActors(_SENTINEL);
    uint256 len = _votes.nominations.length;
    for (uint256 i; i < len; ) {
      unchecked {
        uint256 votes;
        uint256 len2 = sentinels.length;
        for (uint256 j; j < len2; ++j) {
          if (_votes.favorites[sentinels[j]] == _votes.nominations[i]) {
            votes++;
            if (votes == _inheritanceConf.quorum) {
              return _votes.nominations[i];
            }
          }
        }
        ++i;
      }
    }
    return address(0);
  }

  /**
   * @notice Check is a beneficiary has been nominated
   * @param beneficiary The beneficiary to check
   * @return True if the beneficiary has been nominated, false otherwise
   */
  function _isNominated(address beneficiary) internal view virtual returns (bool) {
    uint256 len = _votes.nominations.length;
    for (uint256 i; i < len; ) {
      if (beneficiary == _votes.nominations[i]) {
        return true;
      }
      unchecked {
        ++i;
      }
    }
    return false;
  }

  /**
   * @notice Removes a nominated beneficiary
   * @param beneficiary The beneficiary to remove
   */
  function _popNominated(address beneficiary) internal virtual {
    uint256 len = _votes.nominations.length;
    for (uint256 i; i < len; ) {
      unchecked {
        if (beneficiary == _votes.nominations[i]) {
          // len is > 0
          if (i != len - 1) {
            _votes.nominations[i] = _votes.nominations[len - 1];
          }
          _votes.nominations.pop();
          break;
        }
        ++i;
      }
    }
  }

  /**
   * @notice Resets nominations and votes
   */
  function _resetNominationsAndVotes() internal virtual {
    if (_votes.nominations.length != 0) {
      delete _votes.nominations;
      address[] memory _sentinels = _getActors(_SENTINEL);
      uint256 len = _sentinels.length;
      for (uint256 i; i < len; ) {
        delete _votes.favorites[_sentinels[i]];
        unchecked {
          ++i;
        }
      }
    }
  }

  /**
   * @notice Checks if the sender is a sentinel
   * @return True if the sender is a sentinel, false otherwise
   */
  function _isASentinel() internal view virtual returns (bool) {
    return _actorIndex(_msgSender(), _SENTINEL) != _MAX_ACTORS;
  }

  /**
   * @notice Checks if the owner is still alive
   */
  function _checkIfStillAlive() internal view virtual {
    if (
      // solhint-disable-next-line not-rely-on-time
      block.timestamp - _inheritanceConf.lastProofOfLife < uint256(_inheritanceConf.proofOfLifeDurationInWeeks) * 7 days
    ) revert StillAlive();
  }

  /**
   * @notice Checks if the grace period has expired
   * @return True if the grace period has expired, false otherwise
   */
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

  /**
   * Reset the plugin configuration
   */
  function _resetService() internal {
    delete _actors[_SENTINEL];
    delete _inheritanceConf;
    delete _votes;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */

  uint256[50] private __gap;
}
