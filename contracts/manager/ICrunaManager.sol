// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {CrunaPluginBase} from "../plugins/CrunaPluginBase.sol";

import {IVersioned} from "../utils/IVersioned.sol";
import {ITokenLinkedContract} from "../utils/ITokenLinkedContract.sol";

// import {console} from "hardhat/console.sol";

interface ICrunaManager is ITokenLinkedContract, IVersioned {
  /// @dev A struct to keep info about plugged and unplugged plugins
  /// @param proxyAddress The address of the first implementation of the plugin
  /// @param salt The salt used during the deployment of the plugin. It allows to
  ///  have multiple instances of the same plugin
  /// @param timeLock The time lock for when a plugin is temporarily unauthorized from making transfers
  /// @param canManageTransfer True if the plugin can manage transfers
  /// @param canBeReset True if the plugin requires a reset when the vault is transferred
  /// @param active True if the plugin is active
  /// @param isERC6551Account True if the plugin is an ERC6551 account
  /// @param trusted True if the plugin is trusted
  /// @param banned True if the plugin is banned during the unplug process
  /// @param unplugged True if the plugin has been unplugged
  struct PluginConfig {
    address proxyAddress;
    bytes4 salt;
    uint32 timeLock;
    bool canManageTransfer;
    bool canBeReset;
    bool active;
    bool isERC6551Account;
    bool trusted;
    bool banned;
    bool unplugged;
  }

  /// @dev The plugin element
  /// @param nameId The bytes4 of the hash of the name of the plugin
  /// All plugins' names must be unique, as well as their bytes4 Ids
  /// An official registry will be set up to avoid collisions when plugins
  /// development will be more active. Using the proxy address as a key is
  /// not viable because plugins can be upgraded and the address can change.
  /// @param salt The salt of the plugin
  /// @param active True if the plugin is active
  struct PluginElement {
    bytes4 nameId;
    bytes4 salt;
    // redundant to optimize gas usage
    bool active;
  }

  enum PluginChange {
    Plug,
    Unplug,
    Disable,
    ReEnable,
    Authorize,
    DeAuthorize,
    UnplugForever,
    Reset
  }

  event EmitLockedEventFailed();

  event ProtectorChange(address indexed protector, bool status);

  event ProtectorsAndSafeRecipientsImported(address[] protectors, address[] safeRecipients, uint256 fromTokenId);

  event SafeRecipientChange(address indexed recipient, bool status);

  event PluginStatusChange(string indexed name, bytes4 salt, address plugin_, uint256 change);

  // Emitted when  protectors and safe recipients are removed and all plugins are disabled (if they require it)
  // This event overrides any specific ProtectorChange, SafeRecipientChange and PluginStatusChange event
  event Reset();

  event PluginTrusted(string indexed name, bytes4 salt);

  event ImplementationUpgraded(address indexed implementation_, uint256 currentVersion, uint256 newVersion);

  event PluginResetAttemptFailed(bytes4 _nameId, bytes4 salt);

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
  error PluginHasBeenMarkedAsNotPluggable();
  error PluginAlreadyPlugged();
  error PluginNotFound();
  error InconsistentProxyAddresses();
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
  error CannotImportProtectorsAndSafeRecipientsFromYourself();
  error NotTheSameOwner();
  error SafeRecipientsAlreadySet();
  error NothingToImport();
  error UnsupportedPluginChange();
  error IndexOutOfBounds();

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

  function changePluginStatus(
    string memory name,
    bytes4 salt,
    PluginChange change,
    uint256 timeLock_,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  /// @dev It returns the configuration of a plugin by key
  /// @param key The key of the plugin
  function pluginByKey(bytes8 key) external view returns (PluginConfig memory);

  /// @dev It returns the configuration of all currently plugged plugins
  function allPlugins() external view returns (PluginElement[] memory);

  /// @dev It returns an element of the array of all plugged plugins
  /// @param index The index of the plugin in the array
  function pluginByIndex(uint256 index) external view returns (PluginElement memory);

  /// @dev During an upgrade allows the manager to perform adjustments if necessary.
  /// The parameter is the version of the manager being replaced. This will allow the
  /// new manager to know what to do to adjust the state of the new manager.
  function migrate(uint256 /* version */) external;

  /// @dev Counts the protectors.
  function countActiveProtectors() external view override returns (uint256);

  /// @dev Find a specific protector
  function findProtectorIndex(address protector_) external view override returns (uint256);

  /// @dev Returns true if the address is a protector.
  /// @param protector_ The protector address.
  function isProtector(address protector_) external view override returns (bool);

  /// @dev Returns true if there are protectors.
  function hasProtectors() external view override returns (bool);

  /// @dev Returns true if the token is transferable (since the NFT is ERC6454)
  /// @param to The address of the recipient.
  /// If the recipient is a safe recipient, it returns true.
  function isTransferable(address to) external view override returns (bool);

  /// @dev Returns true if the token is locked (since the NFT is ERC6982)
  function locked() external view override returns (bool);

  /// @dev Set a protector for the token
  /// @param protector_ The protector address
  /// @param active True to add a protector, false to remove it
  /// @param timestamp The timestamp of the signature
  /// @param validFor The validity of the signature
  /// @param signature The signature of the protector
  /// If no signature is required, the field timestamp must be 0
  /// If the operations has been pre-approved by the protector, the signature should be replaced
  /// by a shorter (invalid) one, to tell the signature validator to look for a pre-approval.
  function setProtector(
    address protector_,
    bool active,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function countProtectors() external view returns (uint256);

  function countSafeRecipients() external view returns (uint256);

  /// @dev Imports the protects/safe-recipients from another tokenId owned by the same owner
  function importProtectorsAndSafeRecipientsFrom(uint256 tokenId) external;

  /// @dev Finds a PROTECTOR
  /// @param protector_ The protector address
  function findProtectorIndex(address protector_) external view returns (uint256);

  /// @dev Return the number of active protectors
  function countActiveProtectors() external view returns (uint256);

  /// @dev Return all the protectors
  function getProtectors() external view returns (address[] memory);

  function hasProtectors() external view returns (bool);

  /// @dev Set a safe recipient for the token
  /// @param recipient The recipient address
  /// @param status True if active
  /// @param timestamp The timestamp of the signature
  /// @param validFor The validity of the signature
  function setSafeRecipient(
    address recipient,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  /// @dev Return if the address is a safeRecipient
  function isSafeRecipient(address recipient) external view returns (bool);

  /// @dev Return all the safe recipients
  function getSafeRecipients() external view returns (address[] memory);

  /// @dev Allow to transfer a token when at least 1 protector has been set.
  ///   This is necessary because when a protector is set, the token is not
  ///   transferable anymore.
  /// @param tokenId The id of the token.
  /// @param to The address of the recipient.
  /// @param timeValidation The timestamp of the signature combined with the validity of the signature.
  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function managedTransfer(bytes4 pluginNameId, address to) external;

  function pluginAddress(bytes4 _nameId, bytes4 salt) external view returns (address payable);

  function plugin(bytes4 _nameId, bytes4 salt) external view returns (CrunaPluginBase);

  function trustPlugin(string memory name, bytes4 salt) external;

  function countPlugins() external view returns (uint256, uint256);

  function plugged(string memory name, bytes4 salt) external view returns (bool);

  function pluginIndex(string memory name, bytes4 salt) external view returns (bool, uint256);

  function isPluginActive(string memory name, bytes4 salt) external view returns (bool);

  function listPluginsKeys(bool active) external view returns (bytes8[] memory);
}
