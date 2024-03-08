// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

// erc165 interfaceId 0x8dca4bea
interface IInheritanceCrunaPlugin {
  // @dev Struct to store the configuration for the inheritance
  struct InheritanceConf {
    address beneficiary;
    uint8 quorum;
    uint8 gracePeriodInWeeks;
    uint8 proofOfLifeDurationInWeeks;
    uint32 lastProofOfLife;
    uint32 extendedProofOfLife;
  }

  struct Votes {
    address[] nominations;
    mapping(address => address) favorites;
  }

  event SentinelUpdated(address indexed owner, address indexed sentinel, bool status);

  event InheritanceConfigured(
    address indexed owner,
    uint256 quorum,
    uint256 proofOfLifeDurationInWeeks,
    uint256 gracePeriodInWeeks,
    address beneficiary
  );

  event ProofOfLife(address indexed owner);

  event TransferRequested(address indexed sentinel, address indexed beneficiary);

  event TransferRequestApproved(address indexed sentinel);

  event VotedForBeneficiary(address indexed sentinel, address indexed beneficiary);

  event BeneficiaryApproved(address indexed beneficiary);

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

  // beneficiaries

  // @dev Set a sentinel for the token
  // @param sentinel The sentinel address
  // @param active True to activate, false to deactivate
  // @param timestamp The timestamp of the signature
  // @param validFor The validity of the signature
  // @param signature The signature of the tokensOwner
  function setSentinel(address sentinel, bool active, uint256 timestamp, uint256 validFor, bytes calldata signature) external;

  // @dev Set a list of sentinels for the token
  //   It is a convenience function to set multiple sentinels at once, but it
  //   works only if no protectors have been set up. Useful for initial settings.
  // @param sentinels The sentinel addresses
  // @param emptySignature The signature of the tokensOwner
  //   It is needed to avoid compatibility with setSentinel which expect the
  //   signature coming as calldata
  function setSentinels(address[] memory sentinels, bytes calldata emptySignature) external;

  // @dev Configures an inheritance
  // @param quorum The number of sentinels required to approve a request
  // @param proofOfLifeDurationInWeeks The duration of the Proof-of-Live, i.e., the number
  //   of days after which the sentinels can start the process to inherit the token if the
  //   owner does not prove to be alive
  function configureInheritance(
    uint8 quorum,
    uint8 proofOfLifeDurationInWeeks,
    uint8 gracePeriodInWeeks,
    address beneficiary,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  // @dev Return all the sentinels
  function getSentinelsAndInheritanceData() external view returns (address[] memory, InheritanceConf memory);

  function getVotes() external view returns (address[] memory);

  function countSentinels() external view returns (uint256);

  // @dev allows the user to trigger a Proof-of-Live
  function proofOfLife() external;

  // @dev Allows the sentinels to nominate a beneficiary
  // @param beneficiary The beneficiary address
  // @param vote True to vote, false to retire candidate
  function requestTransfer(address beneficiary) external;

  /** @dev Allows the beneficiary to inherit the token
        There are three scenarios:

        * The user sets a beneficiary. The beneficiary can inherit the NFT as soon as a Proof-of-Life is missed.
        * The user sets more than a single sentinel. The sentinels propose a beneficiary, and when the quorum is reached, the beneficiary can inherit the NFT.
        * The user sets a beneficiary and some sentinels. In this case, the beneficiary has a grace period to inherit the NFT. If after that grace period the beneficiary has not inherited the NFT, the sentinels can propose a new beneficiary.

  */
  function inherit() external;
}
