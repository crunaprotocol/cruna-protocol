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

  function signedByProtector(address tokenOwner_, bytes32 hash, bytes memory signature) external view returns (bool);

  function isSignerAProtector(address tokenOwner_, address signer_) external view;

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
}
