// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {IPlugin} from "../plugins/IPlugin.sol";

interface IPluginExt is IPlugin {
  function nameId() external returns (bytes4);
}

// erc165 interfaceId 0x8dca4bea
interface IManager {
  // @dev Emitted when a protector is set for an tokensOwner
  //   The token owner is useful for historic reason since the NFT can be later transferred to another address.
  //   If that happens, all the protector will be removed, and the new tokenOwner will have to set them again.
  event ProtectorUpdated(address indexed owner, address indexed protector, bool status);

  // @dev Emitted when the level of an allowed recipient is updated
  event SafeRecipientUpdated(address indexed owner, address indexed recipient, bool status);

  event PluginStatusChange(string name, address plugin, bool status);

  event LockFailed(uint256 tokenId, bool status);

  event AllPluginsDisabled();

  struct Plugin {
    address proxyAddress;
    bool canManageTransfer;
    bool active;
  }

  struct PluginStatus {
    string name;
    // redundant to optimize gas usage
    bool active;
  }

  function plug(string memory name, address implementation, bool canManageTransfer) external;

  function disablePlugin(string memory name, bool resetPlugin) external;

  function reEnablePlugin(string memory name, bool resetPlugin) external;

  // simulate ERC-721

  function ownerOf(uint256) external view returns (address);

  // @dev Return the protectors
  // @return The addresses of active protectors set for the tokensOwner
  //   The contract can implement intermediate statuses, like "pending" and "resigned", but the interface
  //   only requires a list of the "active" protectors
  function listProtectors() external view returns (address[] memory);

  // @dev Check if an address is a protector
  // @param protector_ The protector address
  // @return True if the protector is active for the tokensOwner.
  //   Pending protectors are not returned here
  function isAProtector(address protector_) external view returns (bool);

  // @dev Set a protector for the token
  // @param protector_ The protector address
  // @param active True to activate, false to deactivate
  // @param timestamp The timestamp of the signature
  // @param validFor The validity of the signature
  // @param signature The signature of the tokensOwner
  function setProtector(
    address protector_,
    bool active,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  // @dev Finds a PROTECTOR
  // @param protector_ The protector address
  function findProtectorIndex(address protector_) external view returns (uint256);

  // @dev Return the number of active protectors
  function countActiveProtectors() external view returns (uint256);

  // @dev Return all the protectors
  function getProtectors() external view returns (address[] memory);

  function hasProtectors() external view returns (bool);

  // safe recipients

  // @dev Set a safe recipient for the token
  // @param recipient The recipient address
  // @param status True if active
  // @param timestamp The timestamp of the signature
  // @param validFor The validity of the signature
  function setSafeRecipient(
    address recipient,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  // @dev Return if the address is a safeRecipient
  function isSafeRecipient(address recipient) external view returns (bool);

  // @dev Return all the safe recipients
  function getSafeRecipients() external view returns (address[] memory);

  // @dev Allow to transfer a token when at least 1 protector has been set.
  //   This is necessary because when a protector is set, the token is not
  //   transferable anymore.
  // @param tokenId The id of the token.
  // @param to The address of the recipient.
  // @param timeValidation The timestamp of the signature combined with the validity of the signature.
  function protectedTransfer(uint256 tokenId, address to, uint256 timeValidation, bytes calldata signature) external;

  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external;

  // @dev blocks a plugin for a maximum of 30 days from transferring the NFT
  //   If the plugins must be blocked for more time, disable it
  function authorizePluginToTransfer(string memory name, bool authorized, uint256 timeLock) external;

  function pluginAddress(bytes4 _nameId) external view returns (address);

  function plugin(bytes4 _nameId) external view returns (IPluginExt);

  function countPlugins() external view returns (uint256, uint256);

  function plugged(string memory name) external view returns (bool);

  function pluginIndex(string memory name) external view returns (bool, uint256);

  function isPluginActive(string memory name) external view returns (bool);

  function listPlugins(bool active) external view returns (string[] memory);
}
