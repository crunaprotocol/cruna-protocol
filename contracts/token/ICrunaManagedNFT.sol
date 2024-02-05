// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
interface ICrunaManagedNFT {
  event ManagedTransfer(bytes4 indexed pluginNameId, uint256 indexed tokenId);
  event DefaultManagerUpgrade(address newManagerProxy);

  // @dev Allow a plugin to transfer the token
  // @param pluginNameId The hash of the plugin name.
  // @param tokenId The id of the token.
  // @param to The address of the recipient.
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external;

  function setMaxTokenId(uint256 maxTokenId_) external;

  // @dev This function will initialize the contract.
  // @param registry_ The address of the registry contract.
  // @param guardian_ The address of the CrunaManager.sol guardian.
  // @param managerProxy_ The address of the manager proxy.
  function init(address registry_, address guardian_, address managerProxy_) external;

  function upgradeDefaultManager(address payable newManagerProxy) external;

  function activate(uint256 tokenId) external;

  // @dev This function will return the address of the manager for tokenId.
  // @param tokenId The id of the token.
  function managerOf(uint256 tokenId) external view returns (address);

  function isActive(uint256 tokenId) external view returns (bool);
}
