// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

// @dev This contract emits events coming from the managers

interface ICrunaManagerEmitter {
  event ProtectorChange(uint256 indexed tokenId_, address indexed protector, bool status);

  event SafeRecipientChange(uint256 indexed tokenId_, address indexed recipient, bool status);

  event PluginStatusChange(uint256 indexed tokenId_, string indexed name, address plugin_, bool status);

  event PluginAuthorizationChange(
    uint256 indexed tokenId_,
    string indexed name,
    address plugin_,
    bool status,
    uint256 lockTime
  );

  // Emitted when  protectors and safe recipients are removed and all plugins are disabled (if they require it)
  // This event overrides any specific ProtectorChange, SafeRecipientChange and PluginStatusChange event
  event Reset(uint256 indexed tokenId_);

  // a generic, inefficient event that can be used if an upgraded implementation requires more events
  event FutureEvent(
    uint256 indexed tokenId_,
    string indexed eventName,
    address indexed actor,
    bool status,
    uint256 extraUint256,
    bytes32 extraBytes32
  );

  // We let the NFT emit the events, so that it is easier to listen to them
  function emitProtectorChangeEvent(uint256 tokenId_, address protector, bool status) external;

  function emitSafeRecipientChangeEvent(uint256 tokenId_, address recipient, bool status) external;

  function emitPluginStatusChangeEvent(uint256 tokenId_, string memory name, address plugin_, bool status) external;

  function emitPluginAuthorizationChangeEvent(
    uint256 tokenId_,
    string memory name,
    address plugin_,
    bool status,
    uint256 lockTime
  ) external;

  function emitResetEvent(uint256 tokenId_) external;

  function emitFutureEvent(
    uint256 tokenId_,
    string memory eventName,
    address actor,
    bool status,
    uint256 extraUint256,
    bytes32 extraBytes32
  ) external;
}
