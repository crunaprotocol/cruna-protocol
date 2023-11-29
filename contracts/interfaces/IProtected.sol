// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

// erc165 interfaceId 0x0009b66d
interface IProtected {
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
}
