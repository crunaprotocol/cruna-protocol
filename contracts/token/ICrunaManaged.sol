// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
interface ICrunaManaged {
  event ProtectorChange(uint256 indexed tokenId, address indexed protector, bool status);

  event SafeRecipientChange(uint256 indexed tokenId, address indexed recipient, bool status);

  event PluginStatusChange(uint256 indexed tokenId, string name, address plugin, bool status);

  event PluginAuthorizationChange(uint256 indexed tokenId, string name, address plugin, bool status, uint256 lockTime);

  // Emitted when  protectors and safe recipients are removed and all plugins are disabled (if they require it)
  // This event overrides any specific ProtectorChange, SafeRecipientChange and PluginStatusChange event
  event Reset(uint256 indexed tokenId);

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

  // We let the NFT emit the events, so that it is easier to listen to them
  function emitProtectorChangeEvent(uint256 tokenId, address protector, bool status, uint256 protectorsCount) external;

  function emitSafeRecipientChangeEvent(uint256 tokenId, address recipient, bool status) external;

  function emitPluginStatusChangeEvent(uint256 tokenId, string memory name, address plugin, bool status) external;

  function emitPluginAuthorizationChangeEvent(
    uint256 tokenId,
    string memory name,
    address plugin,
    bool status,
    uint256 lockTime
  ) external;

  function emitResetEvent(uint256 tokenId) external;

  function activate(uint256 tokenId) external;

  // @dev This function will return the address of the manager for tokenId.
  // @param tokenId The id of the token.
  function managerOf(uint256 tokenId) external view returns (address);

  function isActive(uint256 tokenId) external view returns (bool);
}
