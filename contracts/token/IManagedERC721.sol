// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

// erc165 interfaceId 0xe19a64da
interface IManagedERC721 {
  // @dev Allow a plugin to transfer the token
  // @param pluginNameId The hash of the plugin name.
  // @param tokenId The id of the token.
  // @param to The address of the recipient.
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external;
}
