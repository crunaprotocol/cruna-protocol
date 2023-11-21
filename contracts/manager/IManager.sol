// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {IActor} from "./IActor.sol";

// erc165 interfaceId 0x8dca4bea
interface IManager {
  /**
   * @dev Emitted when a protector is set for an tokensOwner
       The token owner is useful for historic reason since the NFT can be later transferred to another address.
       If that happens, all the protector will be removed, and the new tokenOwner will have to set them again.
   */
  event ProtectorUpdated(address indexed owner, address indexed protector, bool level);

  /**
   * @dev Emitted when the level of an allowed recipient is updated
   */
  event SafeRecipientUpdated(address indexed owner, address indexed recipient, IActor.Level level);

  /**
   * @dev Emitted when a sentinel is updated
   */
  event SentinelUpdated(address indexed owner, address indexed sentinel, IActor.Level level);

  event Inherited(address indexed protected, uint256 tokenId, address indexed from, address indexed to);

  struct InheritanceConf {
    uint256 quorum;
    uint256 proofOfLifeDurationInDays;
    uint256 lastProofOfLife;
  }

  struct InheritanceRequest {
    address recipient;
    uint256 startedAt;
    address[] approvers;
    // if there is a second thought about the recipient, the sentinel can change it
    // after the request is expired if not approved in the meantime
  }

  /**
  * @dev Return the protectors
  * @return The addresses of active protectors set for the tokensOwner
     The contract can implement intermediate statuses, like "pending" and "resigned", but the interface
     only requires a list of the "active" protectors
  */
  function listProtectors() external view returns (address[] memory);

  /**
   * @dev Check if an address is a protector
   * @param protector_ The protector address
   * @return True if the protector is active for the tokensOwner.
   *   Pending protectors are not returned here
   */
  function isAProtector(address protector_) external view returns (bool);

  function setProtector(
    address protector_,
    bool active,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function findProtector(address protector_) external view returns (uint256, IActor.Level);

  function countActiveProtectors() external view returns (uint256);

  function getProtectors() external view returns (IActor.Actor[] memory);

  // safe recipients

  function setSafeRecipient(
    address recipient,
    IActor.Level level,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function safeRecipientLevel(address recipient) external view returns (IActor.Level);

  function getSafeRecipients() external view returns (IActor.Actor[] memory);

  // beneficiaries

  function setSentinel(
    address sentinel,
    IActor.Level level,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function configureInheritance(uint256 quorum, uint256 proofOfLifeDurationInDays) external;

  function getSentinels() external view returns (IActor.Actor[] memory, InheritanceConf memory);

  function proofOfLife() external;

  function requestTransfer(address beneficiary) external;

  function inherit() external;
}
