// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

// erc165 interfaceId 0x8dca4bea
interface IManager {
  // @dev Emitted when a protector is set for an tokensOwner
  //   The token owner is useful for historic reason since the NFT can be later transferred to another address.
  //   If that happens, all the protector will be removed, and the new tokenOwner will have to set them again.
  event ProtectorUpdated(address indexed owner, address indexed protector, bool status);

  // @dev Emitted when the level of an allowed recipient is updated
  event SafeRecipientUpdated(address indexed owner, address indexed recipient, bool status);

  // @dev Emitted when a sentinel is updated
  event SentinelUpdated(address indexed owner, address indexed sentinel, bool status);

  // @dev Emitted when a beneficiary inherits a token
  event Inherited(address indexed protected, uint256 tokenId, address indexed from, address indexed to);

  // @dev Struct to store the configuration for the inheritance
  struct InheritanceConf {
    uint256 quorum;
    uint256 proofOfLifeDurationInDays;
    uint256 lastProofOfLife;
  }

  // @dev Struct to store the request for a transfer to an heir
  struct InheritanceRequest {
    address recipient;
    uint256 startedAt;
    address[] approvers;
    // if there is a second thought about the recipient, the sentinel can change it
    // after the request is expired if not approved in the meantime
  }

  // @dev Return the protectors
  // @return The addresses of active protectors set for the tokensOwner
  //   The contract can implement intermediate statuses, like "pending" and "resigned", but the interface
  //   only requires a list of the "active" protectors
  function listProtectors() external view returns (address[] memory);

  // @dev Check if an address is a protector
  // @param protector_ The protector address
  // @return True if the protector is active for the tokensOwner.
  //   Pending protectors are not returned here
  function isAProtector(address protector_) external view returns (bool);

  // @dev Set a protector for the token
  // @param protector_ The protector address
  // @param active True to activate, false to deactivate
  // @param timestamp The timestamp of the signature
  // @param validFor The validity of the signature
  // @param signature The signature of the tokensOwner
  function setProtector(
    address protector_,
    bool active,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  // @dev Finds a PROTECTOR
  // @param protector_ The protector address
  function findProtectorIndex(address protector_) external view returns (uint256);

  // @dev Return the number of active protectors
  function countActiveProtectors() external view returns (uint256);

  // @dev Return all the protectors
  function getProtectors() external view returns (address[] memory);

  // safe recipients

  // @dev Set a safe recipient for the token
  // @param recipient The recipient address
  // @param status True if active
  // @param timestamp The timestamp of the signature
  // @param validFor The validity of the signature
  function setSafeRecipient(
    address recipient,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  // @dev Return if the address is a safeRecipient
  function isSafeRecipient(address recipient) external view returns (bool);

  // @dev Return all the safe recipients
  function getSafeRecipients() external view returns (address[] memory);

  // beneficiaries

  // @dev Set a sentinel for the token
  // @param sentinel The sentinel address
  // @param active True to activate, false to deactivate
  // @param timestamp The timestamp of the signature
  // @param validFor The validity of the signature
  // @param signature The signature of the tokensOwner
  function setSentinel(address sentinel, bool active, uint256 timestamp, uint256 validFor, bytes calldata signature) external;

  // @dev Configures an inheritance
  // @param quorum The number of sentinels required to approve a request
  // @param proofOfLifeDurationInDays The duration of the Proof-of-Live, i.e., the number
  //   of days after which the sentinels can start the process to inherit the token if the
  //   owner does not prove to be alive
  function configureInheritance(uint256 quorum, uint256 proofOfLifeDurationInDays) external;

  // @dev Return all the sentinels
  function getSentinels() external view returns (address[] memory, InheritanceConf memory);

  // @dev allows the user to trigger a Proof-of-Live
  function proofOfLife() external;

  // @dev Allows the sentinels to nominate a beneficiary
  // @param beneficiary The beneficiary address
  function requestTransfer(address beneficiary) external;

  // @dev Allows the beneficiary to inherit the token
  function inherit() external;
}
