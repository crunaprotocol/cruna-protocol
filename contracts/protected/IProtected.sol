// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {IActor} from "../manager/IActor.sol";

// erc165 interfaceId 0x8dca4bea
interface IProtected {
  // @dev Emitted when a protector is set for an tokensOwner
  event ProtectorUpdated(address indexed tokensOwner, address indexed protector, bool status);

  // @dev Emitted when the level of an allowed recipient is updated
  event SafeRecipientUpdated(address indexed owner, address indexed recipient, IActor.Level level);

  // @dev Emitted when a beneficiary is updated
  event BeneficiaryUpdated(address indexed owner, address indexed beneficiary, IActor.Level status);

  // @dev Allow to transfer a token when at least 1 protector has been set.
  //   This is necessary because when a protector is set, the token is not
  //   transferable anymore.
  // @param tokenId The id of the token.
  // @param to The address of the recipient.
  // @param timestamp The timestamp of the signature.
  // @param validFor The validity of the signature.
  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  // @dev Transfer a token to a beneficiary when the token is inherit.
  //   The process is valid at any time, despite the existence of protectors,
  //   as long as a Proof-of-Life has been missed and the sentinels have nominated
  //   the beneficiary.
  // @param tokenId The id of the token.
  // @param to The address of the beneficiary.
  function managedTransfer(uint256 tokenId, address to) external;
}
