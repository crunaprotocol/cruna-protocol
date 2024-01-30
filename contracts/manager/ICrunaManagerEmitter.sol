// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

// @dev This contract emits events coming from the managers

interface ICrunaManagerEmitter {
  event ProtectorChange(uint256 indexed tokenId, address indexed protector, bool status);

  event SafeRecipientChange(uint256 indexed tokenId, address indexed recipient, bool status);

  event PluginStatusChange(uint256 indexed tokenId, string name, address plugin, bool status);

  event PluginAuthorizationChange(uint256 indexed tokenId, string name, address plugin, bool status, uint256 lockTime);

  // Emitted when  protectors and safe recipients are removed and all plugins are disabled (if they require it)
  // This event overrides any specific ProtectorChange, SafeRecipientChange and PluginStatusChange event
  event Reset(uint256 indexed tokenId);

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

}
