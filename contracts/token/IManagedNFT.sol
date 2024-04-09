// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

/**
 * @title IManagedNFT
 * @author Francesco Sullo <francesco@sullo.co>
 * @notice Interface for a managed NFT
 */
interface IManagedNFT {
  /**
   * @notice Emitted when a token is transferred by a plugin
   * @param pluginNameId The hash of the plugin name.
   * @param tokenId The id of the token.
   */
  event ManagedTransfer(bytes4 indexed pluginNameId, uint256 indexed tokenId);

  /**
   * @notice Allow a plugin to transfer the token
   * @param pluginNameId The hash of the plugin name.
   * @param tokenId The id of the token.
   * @param to The address of the recipient.
   */
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external payable;
}
