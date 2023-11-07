// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {IActor} from "./IActor.sol";

// erc165 interfaceId 0x8dca4bea
interface IManager {
  /**
   * @dev Emitted when a protector is set for an tokensOwner
   */
  event ProtectorUpdated(address indexed tokensOwner, address indexed protector, bool status);

  /**
   * @dev Emitted when the level of an allowed recipient is updated
   */
  event SafeRecipientUpdated(address indexed owner, address indexed recipient, IActor.Level level);

  /**
   * @dev Emitted when a beneficiary is updated
   */
  event BeneficiaryUpdated(address indexed owner, address indexed beneficiary, IActor.Status status);

  event Inherited(address indexed protected, uint256 tokenId, address indexed from, address indexed to);

  error TimestampZero();
  error Forbidden();
  error NotTheTokenOwner();
  error NotApprovable();
  error NotApprovableForAll();
  error NotTheContractDeployer();
  error TokenDoesNotExist();
  error SenderDoesNotOwnAnyToken();
  error ProtectorNotFound();
  error TokenAlreadyBeingTransferred();
  error AssociatedToAnotherOwner();
  error ProtectorAlreadySet();
  error ProtectorAlreadySetByYou();
  error NotAProtector();
  error NotOwnByRelatedOwner();
  error NotPermittedWhenProtectorsAreActive();
  error TokenIdTooBig();
  error PendingProtectorNotFound();
  error ResignationAlreadySubmitted();
  error UnsetNotStarted();
  error NotTheProtector();
  error NotATokensOwner();
  error ResignationNotSubmitted();
  error InvalidDuration();
  error NoActiveProtectors();
  error ProtectorsAlreadyLocked();
  error ProtectorsUnlockAlreadyStarted();
  error ProtectorsUnlockNotStarted();
  error ProtectorsNotLocked();
  error TimestampInvalidOrExpired();
  error WrongDataOrNotSignedByProtector();
  error WrongDataOrNotSignedByProposedProtector();
  error SignatureAlreadyUsed();
  error OperatorAlreadyActive();
  error OperatorNotActive();
  error NotTheVaultManager();
  error QuorumCannotBeZero();
  error QuorumCannotBeGreaterThanBeneficiaries();
  error BeneficiaryNotConfigured();
  error NotExpiredYet();
  error BeneficiaryAlreadyRequested();
  error InconsistentRecipient();
  error NotABeneficiary();
  error RequestAlreadyApproved();
  error NotTheRecipient();
  error Unauthorized();
  error NotTransferable();
  error InvalidProtectedERC721();
  error NotTheBondedProtectedERC721();
  error NotYourProtector();
  error NotAnActiveProtector();
  error CannotBeYourself();

  struct BeneficiaryConf {
    uint256 quorum;
    uint256 proofOfLifeDurationInDays;
    uint256 lastProofOfLife;
  }

  struct BeneficiaryRequest {
    address recipient;
    uint256 startedAt;
    address[] approvers;
    // if there is a second thought about the recipient, the beneficiary can change it
    // after the request is expired if not approved in the meantime
  }

  /**
  * @dev Return the protectors set for the tokensOwner
  * @notice It is not the specific tokenId that is protected, is all the tokens owned by
     tokensOwner_ that are protected. So, protectors are set for the tokensOwner, not for the specific token.
     It is this way to reduce gas consumption.
  * @param tokensOwner_ The tokensOwner address
  * @return The addresses of active protectors set for the tokensOwner
     The contract can implement intermediate statuses, like "pending" and "resigned", but the interface
     only requires a list of the "active" protectors
  */
  function hasProtectors(address tokensOwner_) external view returns (address[] memory);

  /**
   * @dev Check if an address is a protector for an tokensOwner
   * @param tokensOwner_ The tokensOwner address
   * @param protector_ The protector address
   * @return True if the protector is active for the tokensOwner.
   *   Pending protectors are not returned here
   */
  function isProtectorFor(address tokensOwner_, address protector_) external view returns (bool);

  function setProtector(
    address protector_,
    bool active,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function findProtector(address tokensOwner_, address protector_) external view returns (uint256, IActor.Status);

  function countActiveProtectors(address tokensOwner_) external view returns (uint256);

  function setSignatureAsUsed(bytes calldata signature) external;

  /**
   * @dev Verifies if the transfer request is signed by a protector
   * @param tokenOwner_ The token owner
   * @param hash The hash of the transfer request
   * @param signature The signature of the transfer request
   * @return True if the transfer request is signed by a protector
   */
  function signedByProtector(address tokenOwner_, bytes32 hash, bytes memory signature) external view returns (bool);

  /**
   * @dev Checks if a signature has been used
   * @param signature The signature of the transfer request
   * @return True if the signature has been used
   */
  function isSignatureUsed(bytes calldata signature) external view returns (bool);

  function isNotExpired(uint256 timestamp, uint256 validFor) external view;

  function isSignerAProtector(address tokenOwner_, address signer_) external view;

  function checkIfSignatureUsedAndUseIfNot(bytes calldata signature) external;

  function validateTimestampAndSignature(
    address tokenOwner_,
    uint256 timestamp,
    uint256 validFor,
    bytes32 hash,
    bytes calldata signature
  ) external view;

  function invalidateSignatureFor(bytes32 hash, bytes calldata signature) external;

  // safe recipients

  function setSafeRecipient(
    address recipient,
    IActor.Level level,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function safeRecipientLevel(address tokenOwner_, address recipient) external view returns (IActor.Level);

  function getSafeRecipients(address tokenOwner_) external view returns (IActor.Actor[] memory);

  // beneficiaries

  function setBeneficiary(
    address beneficiary,
    IActor.Status status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function configureBeneficiary(uint256 quorum, uint256 proofOfLifeDurationInDays) external;

  function getBeneficiaries(address tokenOwner_) external view returns (IActor.Actor[] memory, BeneficiaryConf memory);

  function proofOfLife() external;

  function requestTransfer(address tokenOwner_, address beneficiaryRecipient) external;

  function inherit(address tokenOwner_) external;

  // validation

  function recover(bytes32 digest, bytes calldata signature) external view returns (address);

  // digests

  function setProtectorDigest(
    address protector,
    bool active,
    uint256 timestamp,
    uint256 validFor
  ) external view returns (bytes32);

  function transferRequestDigest(address to, uint256 timestamp, uint256 validFor) external view returns (bytes32);

  function recipientRequestDigest(
    address recipient,
    uint256 level,
    uint256 timestamp,
    uint256 validFor
  ) external view returns (bytes32);

  function beneficiaryRequestDigest(
    address guardian,
    uint256 status,
    uint256 timestamp,
    uint256 validFor
  ) external view returns (bytes32);
}
