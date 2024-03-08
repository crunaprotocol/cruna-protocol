// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {CrunaPluginBase} from "../plugins/CrunaPluginBase.sol";

import {IVersioned} from "../utils/IVersioned.sol";
import {ITokenLinkedContract} from "../utils/ITokenLinkedContract.sol";

// import {console} from "hardhat/console.sol";

interface ICrunaManager is ITokenLinkedContract, IVersioned {
  enum PluginStatus {
    Unplugged,
    PluggedAndActive,
    PluggedAndInactive
  }

  struct CrunaPlugin {
    address proxyAddress;
    bool canManageTransfer;
    bool canBeReset;
    bool active;
    bool isERC6551Account;
    bool trusted;
    bytes4 salt;
  }

  struct PluginElement {
    string name;
    bytes4 salt;
    // redundant to optimize gas usage
    bool active;
  }

  event EmitLockedEventFailed();

  event ProtectorChange(address indexed protector, bool status);

  event ProtectorsAndSafeRecipientsImported(address[] protectors, address[] safeRecipients, uint256 fromTokenId);

  event SafeRecipientChange(address indexed recipient, bool status);

  event PluginStatusChange(string indexed name, bytes4 salt, address plugin_, PluginStatus status);

  event PluginAuthorizationChange(string indexed name, bytes4 salt, address plugin_, bool status, uint256 lockTime);

  // Emitted when  protectors and safe recipients are removed and all plugins are disabled (if they require it)
  // This event overrides any specific ProtectorChange, SafeRecipientChange and PluginStatusChange event
  event Reset();

  event PluginTrusted(string indexed name, bytes4 salt);

  event ImplementationUpgraded(address indexed implementation_, uint256 currentVersion, uint256 newVersion);

  event PluginResetAttempt(bytes4 _nameId, bytes4 salt, bool success);

  error UntrustedImplementation();
  error InvalidVersion();
  error PluginRequiresUpdatedManager(uint256 requiredVersion);
  error Forbidden();
  error NotAManager();
  error ProtectorNotFound();
  error ProtectorAlreadySetByYou();
  error ProtectorsAlreadySet();
  error CannotBeYourself();
  error NotTheAuthorizedPlugin();
  error PluginNumberOverflow();
  error PluginAlreadyPlugged();
  error PluginNotFound();
  error PluginNotFoundOrDisabled();
  error PluginNotDisabled();
  error PluginAlreadyDisabled();
  error PluginNotAuthorizedToManageTransfer();
  error PluginAlreadyAuthorized();
  error PluginAlreadyUnauthorized();
  error NotATransferPlugin();
  error InvalidImplementation();
  error InvalidTimeLock();
  error InvalidValidity();
  error InvalidAccountStatus();
  error UntrustedImplementationsNotAllowedToMakeTransfers();
  error StillUntrusted();
  error PluginAlreadyTrusted();
  error CannotimportProtectorsAndSafeRecipientsFromYourself();
  error NotTheSameOwner();
  error SafeRecipientsAlreadySet();
  error NothingToImport();

  function upgrade(address implementation_) external;

  function plug(
    string memory name,
    address pluginProxy,
    bool canManageTransfer,
    bool isERC6551Account,
    bytes4 salt,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function disablePlugin(
    string memory name,
    bytes4 salt,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function reEnablePlugin(
    string memory name,
    bytes4 salt,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function isTransferable(address to) external view returns (bool);

  function locked() external view returns (bool);

  // simulate ERC-721

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

  function countProtectors() external view returns (uint256);

  function countSafeRecipients() external view returns (uint256);

  // @dev Imports the protects/safe-recipients from another tokenId owned by the same owner
  function importProtectorsAndSafeRecipientsFrom(uint256 tokenId) external;

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

  function managedTransfer(bytes4 pluginNameId, address to) external;

  // @dev blocks a plugin for a maximum of 30 days from transferring the NFT
  //   If the plugins must be blocked for more time, disable it
  function authorizePluginToTransfer(
    string memory name,
    bytes4 salt,
    bool authorized,
    uint256 timeLock,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function pluginAddress(bytes4 _nameId, bytes4 salt) external view returns (address payable);

  function plugin(bytes4 _nameId, bytes4 salt) external view returns (CrunaPluginBase);

  function unplug(string memory name, bytes4, uint256 timestamp, uint256 validFor, bytes calldata signature) external;

  function trustPlugin(string memory name, bytes4 salt) external;

  function countPlugins() external view returns (uint256, uint256);

  function plugged(string memory name, bytes4 salt) external view returns (bool);

  function pluginIndex(string memory name, bytes4 salt) external view returns (bool, uint256);

  function isPluginActive(string memory name, bytes4 salt) external view returns (bool);

  function listPlugins(bool active) external view returns (string[] memory);
}
