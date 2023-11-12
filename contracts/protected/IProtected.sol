// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {IActor} from "./IActor.sol";

// erc165 interfaceId 0x8dca4bea
interface IProtected {
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

  /**
   * @dev Transfers a token to a recipient usign a valid signed transferRequest
   * @notice The function MUST be executed by the owner
   * @param tokenId The token id
   * @param to The address of the recipient
   * @param timestamp The timestamp of the transfer request
   * @param signature The signature of the transfer request, signed by an active protector
   */
  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function managedTransfer(uint256 tokenId, address to) external;
}
