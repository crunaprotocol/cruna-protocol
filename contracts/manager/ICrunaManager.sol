// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ICrunaPlugin} from "../plugins/ICrunaPlugin.sol";

import {INamed} from "../utils/INamed.sol";
import {IBoundContractExtended} from "../utils/IBoundContractExtended.sol";
import {IReference} from "../token/IReference.sol";
import {IVault} from "../token/IVault.sol";

//import {console} from "hardhat/console.sol";

interface ICrunaManager is IBoundContractExtended, INamed, IReference {
  event EmitEventFailed(EventAction action);

  event ProtectorChange(address indexed protector, bool status);

  event SafeRecipientChange(address indexed recipient, bool status);

  event PluginStatusChange(string indexed name, address plugin_, bool status);

  event PluginAuthorizationChange(string indexed name, address plugin_, bool status, uint256 lockTime);

  // Emitted when  protectors and safe recipients are removed and all plugins are disabled (if they require it)
  // This event overrides any specific ProtectorChange, SafeRecipientChange and PluginStatusChange event
  event Reset();

  enum EventAction {
    ProtectorChange,
    SafeRecipientChange,
    PluginStatusChange,
    Reset
  }

  struct CrunaPlugin {
    address proxyAddress;
    bool canManageTransfer;
    bool canBeReset;
    bool active;
  }

  struct PluginStatus {
    string name;
    // redundant to optimize gas usage
    bool active;
  }

  function upgrade(address implementation_) external;

  //  function getImplementation() external view returns (address);

  // simulate ERC-721 to allow plugins to be deployed via ERC-6551 Registry
  function ownerOf(uint256) external view returns (address);

  function emitter() external view returns (address);

  function vault() external view returns (IVault);

  function plug(
    string memory name,
    address pluginProxy,
    bool canManageTransfer,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function disablePlugin(
    string memory name,
    bool resetPlugin,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function reEnablePlugin(
    string memory name,
    bool resetPlugin,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function isTransferable(address to) external view returns (bool);

  function locked() external view returns (bool);

  // simulate ERC-721

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
  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function updateEmitterForPlugin(bytes4 pluginNameId, address newEmitter) external;

  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external;

  // @dev blocks a plugin for a maximum of 30 days from transferring the NFT
  //   If the plugins must be blocked for more time, disable it
  function authorizePluginToTransfer(
    string memory name,
    bool authorized,
    uint256 timeLock,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function pluginAddress(bytes4 _nameId) external view returns (address);

  function plugin(bytes4 _nameId) external view returns (ICrunaPlugin);

  function countPlugins() external view returns (uint256, uint256);

  function plugged(string memory name) external view returns (bool);

  function pluginIndex(string memory name) external view returns (bool, uint256);

  function isPluginActive(string memory name) external view returns (bool);

  function listPlugins(bool active) external view returns (string[] memory);
}
