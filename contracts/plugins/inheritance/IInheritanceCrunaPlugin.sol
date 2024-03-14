// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

/**
 * @title IInheritanceCrunaPlugin
 * @notice Interface for the inheritance plugin
 */
interface IInheritanceCrunaPlugin {
  /**
   * @dev Struct to store the configuration for the inheritance
   * @param beneficiary The beneficiary address
   * @param quorum The number of sentinels required to approve a request
   * @param gracePeriodInWeeks The grace period in weeks
   * @param proofOfLifeDurationInWeeks The duration of the Proof-of-Live, i.e., the number
   * of days after which the sentinels can start the process to inherit the token if the
   * owner does not prove to be alive
   * @param lastProofOfLife The timestamp of the last Proof-of-Life
   * @param extendedProofOfLife The timestamp of the extended Proof-of-Life
   */
  struct InheritanceConf {
    address beneficiary;
    uint8 quorum;
    uint8 gracePeriodInWeeks;
    uint8 proofOfLifeDurationInWeeks;
    uint32 lastProofOfLife;
    uint32 extendedProofOfLife;
  }

  /**
   * @dev Struct to store the votes
   * @param nominations The nominated beneficiaries
   * @param favorites The favorite beneficiary for each sentinel
   */
  struct Votes {
    address[] nominations;
    mapping(address voter => address beneficiary) favorites;
  }

  /**
   * @dev Emitted when a sentinel is updated
   * @param owner The owner address
   * @param sentinel The sentinel address
   * @param status True if the sentinel is active, false if it is not
   */
  event SentinelUpdated(address indexed owner, address indexed sentinel, bool status);

  /**
   * @dev Emitted when the inheritance is configured
   * @param owner The owner address
   * @param quorum The number of sentinels required to approve a request
   * @param proofOfLifeDurationInWeeks The duration of the Proof-of-Live, i.e., the number
   * of days after which the sentinels can start the process to inherit the token if the
   * owner does not prove to be alive
   * @param gracePeriodInWeeks The grace period in weeks
   * @param beneficiary The beneficiary address
   */
  event InheritanceConfigured(
    address indexed owner,
    uint256 quorum,
    uint256 proofOfLifeDurationInWeeks,
    uint256 gracePeriodInWeeks,
    address beneficiary
  );

  /**
   * @dev Emitted when a Proof-of-Life is triggered
   * @param owner The owner address
   */
  event ProofOfLife(address indexed owner);

  /**
   * @dev Emitted when a sentinel votes for a beneficiary
   * @param sentinel The sentinel address
   * @param beneficiary The beneficiary address. If the address == address(0), the vote
   * is to retire the beneficiary
   */
  event VotedForBeneficiary(address indexed sentinel, address indexed beneficiary);

  /**
   * @dev Emitted when a beneficiary is approved
   * @param beneficiary The beneficiary address
   */
  event BeneficiaryApproved(address indexed beneficiary);

  /**
   * @dev Error returned when the quorum is set to 0
   */
  error QuorumCannotBeZero();

  /**
   * @dev Error returned when the quorum is greater than the number of sentinels
   */
  error QuorumCannotBeGreaterThanSentinels();

  /**
   * @dev Error returned when the inheritance is not set
   */
  error InheritanceNotConfigured();

  /**
   * @dev Error returned when the owner is still alive, i.e., there is a Proof-of-Life event
   * more recent than the Proof-of-Life duration
   */
  error StillAlive();

  /**
   * @dev Error returned when the sender is not a sentinel
   */
  error NotASentinel();

  /**
   * @dev Error returned when the sender is not the beneficiary
   */
  error NotTheBeneficiary();

  /**
   * @dev Error returned when the beneficiary is not set
   */
  error BeneficiaryNotSet();

  /**
   * @dev Error returned when trying to vote for a beneficiary, while
   * the grace period for the current beneficiary is not over
   */
  error WaitingForBeneficiary();

  /**
   * @dev Error returned when passing a signature with a validFor > MAX_VALID_FOR
   */
  error InvalidValidity();

  /**
   * @dev Error returned when trying to retire a not-found vote
   */
  error NoVoteToRetire();

  /**
   * @dev Error returned when the parameters are invalid
   */
  error InvalidParameters();

  // beneficiaries

  /**
   * @dev Set a sentinel for the token
   * @param sentinel The sentinel address
   * @param active True to activate, false to deactivate
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the tokensOwner
   */
  function setSentinel(address sentinel, bool active, uint256 timestamp, uint256 validFor, bytes calldata signature) external;

  /**
   * @dev Set a list of sentinels for the token
   * It is a convenience function to set multiple sentinels at once, but it
   * works only if no protectors have been set up. Useful for initial settings.
   * @param sentinels The sentinel addresses
   * @param emptySignature The signature of the tokensOwner
   */
  function setSentinels(address[] memory sentinels, bytes calldata emptySignature) external;

  /**
   * @dev Configures an inheritance
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
  ) external;

  /**
   * @dev Return all the sentinels and the inheritance data
   */
  function getSentinelsAndInheritanceData() external view returns (address[] memory, InheritanceConf memory);

  /**
   * @dev Return all the votes
   */
  function getVotes() external view returns (address[] memory);

  /**
   * @dev Return the number of sentinels
   */
  function countSentinels() external view returns (uint256);

  /**
   * @dev allows the user to trigger a Proof-of-Live
   */
  function proofOfLife() external;

  /**
   * @dev Allows the sentinels to nominate a beneficiary
   * @param beneficiary The beneficiary address
   * If the beneficiary is address(0), the vote is to retire a previously voted beneficiary
   */
  function voteForBeneficiary(address beneficiary) external;

  /**
   * @dev Allows the beneficiary to inherit the token
   */
  function inherit() external;
}
