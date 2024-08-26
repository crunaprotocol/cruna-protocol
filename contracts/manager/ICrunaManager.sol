// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {CrunaManagedService} from "../services/CrunaManagedService.sol";

import {IVersioned} from "../utils/IVersioned.sol";
import {IERC7656Service} from "erc7656/interfaces/IERC7656Service.sol";

interface ICrunaManager is IERC7656Service, IVersioned {
  /**
   * @notice A struct to keep info about plugged and unplugged services
   * @param deployed True all the time. Used to verify if the plugin as been deployed
   * @param canManageTransfer True if the plugin can manage transfers
   * @param canBeReset True if the plugin requires a reset when the vault is transferred
   * @param active True if the plugin is active
   * @param isERC6551Account True if the plugin is an ERC6551 account
   * @param trusted True if the plugin is trusted
   * @param banned True if the plugin is banned during the unplug process
   * @param unplugged True if the plugin has been unplugged
   * @param timeLock The time lock for when a plugin is temporarily unauthorized from making transfers
   */
  struct PluginConfig {
    bool deployed;
    bool canManageTransfer;
    bool canBeReset;
    bool active;
    bool isERC6551Account;
    bool trusted;
    bool banned;
    bool unplugged;
    uint32 timeLock;
  }

  /**
   * @notice It enumerates the action that can be performed when changing the status of a plugin
   */
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

  /**
   * @notice Event emitted when the manager call to the NFT to emit a Locked event fails.
   */
  event EmitLockedEventFailed();

  /**
   * @notice Event emitted when the `status` of `protector` changes
   */
  event ProtectorChange(address indexed protector, bool status);

  /**
   * @notice Event emitted when protectors and safe recipients are imported from another token
   */
  event ProtectorsAndSafeRecipientsImported(address[] protectors, address[] safeRecipients, uint256 fromTokenId);

  /**
   * @notice Event emitted when the `status` of `recipient` changes
   */
  event SafeRecipientChange(address indexed recipient, bool status);

  /**
   * @notice Event emitted when
   * the status of plugin identified by `name` and `salt`, and deployed to `pluginAddress` gets a specific `change`
   */
  event PluginStatusChange(bytes32 indexed key, address indexed pluginAddress, uint256 change);

  /**
   * @notice Emitted when protectors and safe recipients are removed and all services are disabled (if they require it)
   * This event overrides any specific ProtectorChange, SafeRecipientChange and PluginStatusChange event
   */
  event Reset();

  /**
   * @notice Emitted when a plugin initially plugged despite being not trusted, is trusted by the CrunaGuardian
   */
  event PluginTrusted(bytes32 indexed key);

  /**
   * @notice Emitted when the implementation of the manager is upgraded
   * @param implementation_ The address of the new implementation
   * @param oldVersion The old version of the manager
   * @param newVersion The new version of the manager
   */
  event ImplementationUpgraded(address indexed implementation_, uint256 oldVersion, uint256 newVersion);

  /**
   * @notice Event emitted when the attempt to reset a plugin fails
   * When this happens, the token owner can unplug the plugin and mark it as banned to avoid future re-plugs
   */
  event PluginResetAttemptFailed(bytes32 indexed key);

  /**
   * @notice Returned when trying to upgrade the manager to an untrusted implementation
   */
  error UntrustedImplementation(address implementation);

  /**
   * @notice Returned when trying to upgrade to an older version of the manager
   */
  error InvalidVersion(uint256 oldVersion, uint256 newVersion);

  /**
   * @notice Returned when trying to plug a plugin that requires a new version of the manager
   */
  error PluginRequiresUpdatedManager(uint256 requiredVersion);

  /**
   * @notice Returned when the sender has no right to execute a function
   */
  error Forbidden();

  /**
   * @notice Returned when the sender is not a manager
   */
  error NotAManager(address sender);

  /**
   * @notice Returned when a protector is not found
   */
  error ProtectorNotFound(address protector);

  /**
   * @notice Returned when a protector is already set by the sender
   */
  error ProtectorAlreadySetByYou(address protector);

  /**
   * @notice Returned when a protector is already set
   */
  error ProtectorsAlreadySet();

  /**
   * @notice Returned when trying to set themself as a protector
   */
  error CannotBeYourself();

  /**
   * @notice Returned when the managed transfer is called not by the right plugin
   */
  error NotTheAuthorizedPlugin(address callingPlugin);

  /**
   * @notice Returned when the pluggin service is not a managed service
   */
  error UnmanagedService();

  /**
   * @notice Returned when there is no more space for services
   */
  error PluginNumberOverflow();

  /**
   * @notice Returned when the plugin has been banned and marked as not pluggable
   */
  error PluginHasBeenMarkedAsNotPluggable();

  /**
   * @notice Returned when a plugin has already been plugged
   */
  error PluginAlreadyPlugged();

  /**
   * @notice Returned when a plugin is not found
   */
  error PluginNotFound();

  /**
   * @notice Returned when trying to plug an unplugged plugin and the address of the implementation differ
   */
  error InconsistentProxyAddresses(address currentAddress, address proposedAddress);

  /**
   * @notice Returned when a plugin is not found or is disabled
   */
  error PluginNotFoundOrDisabled();

  /**
   * @dev Returned when tryng to re-enable a not-disabled plugin
   */
  error PluginNotDisabled();

  /**
   * @dev Returned when trying to disable a plugin that is already disabled
   */
  error PluginAlreadyDisabled();

  /**
   * @dev Returned when a plugin tries to transfer the NFT without authorization
   */
  error PluginNotAuthorizedToManageTransfer();

  /**
   * @dev Returned when a plugin has already been authorized
   */
  error PluginAlreadyAuthorized();

  /**
   * @dev Returned when a plugin has already been unauthorized
   */
  error PluginAlreadyUnauthorized();

  /**
   * @dev Returned when a plugin is not authorized to make transfers
   */
  error NotATransferPlugin();

  /**
   * @dev Returned when trying to plug a plugin that responds to a different nameId
   */
  error InvalidImplementation(bytes4 nameIdReturnedByPlugin, bytes4 proposedNameId);

  /**
   * @dev Returned when setting an invalid TimeLock when temporarily de-authorizing a plugin
   */
  error InvalidTimeLock(uint256 timeLock);

  /**
   * @dev Returned when calling a function with a validity overflowing the maximum value
   */
  error InvalidValidity();

  /**
   * @dev Returned when plugging plugin as ERC6551 while the plugin is not an ERC6551 account, or vice versa
   */
  error InvalidERC6551Status();

  /**
   * @dev Returned when trying to make a transfer with an untrusted plugin, when the NFT accepts only trusted ones
   */
  error UntrustedImplementationsNotAllowedToMakeTransfers();

  /**
   * @dev Returned if trying to trust a plugin that is still untrusted
   */
  error StillUntrusted(bytes32 key);

  /**
   * @dev Returned if a plugin has already been trusted
   */
  error PluginAlreadyTrusted();

  /**
   * @dev Returned when trying to import protectors and safe recipients from the token itself
   */
  error CannotImportProtectorsAndSafeRecipientsFromYourself();

  /**
   * @dev Returned when the owner of the exporter token is different from the owner of the importer token
   */
  error NotTheSameOwner(address originSOwner, address owner);

  /**
   * @dev Returned when some safe recipients have already been set
   */
  error SafeRecipientsAlreadySet();

  /**
   * @dev Returned when the origin token has no protectors and no safe recipients
   */
  error NothingToImport();

  /**
   * @dev Returned when trying to change the status of a plugin to an unsupported mode
   */
  error UnsupportedPluginChange();

  /**
   * @dev Returned when trying to get the index of a plugin in the allPlugins array, but that index is out of bounds
   */
  error IndexOutOfBounds();

  /**
   * @dev Returned when trying to use a function that requires protectors, but no protectors are set
   */
  error ToBeUsedOnlyWhenProtectorsAreActive();

  /**
   * @dev It returns the configuration of a plugin by key
   * @param key The key of the plugin
   */
  function pluginByKey(bytes32 key) external view returns (PluginConfig memory);

  /**
   * @dev It returns the configuration of all currently plugged services
   */
  function allPlugins() external view returns (bytes32[] memory);

  /**
   * @dev It returns an element of the array of all plugged services
   * @param index The index of the plugin in the array
   */
  function pluginByIndex(uint256 index) external view returns (bytes32);

  /**
   * @dev During an upgrade allows the manager to perform adjustments if necessary.
   * The parameter is the version of the manager being replaced. This will allow the
   * new manager to know what to do to adjust the state of the new manager.
   */
  function migrate(uint256 /* version */) external;

  /**
   * @dev Find a specific protector
   */
  function findProtectorIndex(address protector_) external view returns (uint256);

  /**
   * @dev Returns true if the address is a protector.
   * @param protector_ The protector address.
   */
  function isProtector(address protector_) external view returns (bool);

  /**
   * @dev Returns true if there are protectors.
   */
  function hasProtectors() external view returns (bool);

  /**
   * @dev Returns true if the token is transferable (since the NFT is ERC6454)
   * @param to The address of the recipient.
   * If the recipient is a safe recipient, it returns true.
   */
  function isTransferable(address to) external view returns (bool);

  /**
   * @dev Returns true if the token is locked (since the NFT is ERC6982)
   */
  function locked() external view returns (bool);

  /**
   * @dev Counts how many protectors have been set
   */
  function countProtectors() external view returns (uint256);

  /**
   * @dev Counts the safe recipients
   */
  function countSafeRecipients() external view returns (uint256);

  /**
   * @dev Set a protector for the token
   * @param protector_ The protector address
   * @param status True to add a protector, false to remove it
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the protector
   * If no signature is required, the field timestamp must be 0
   * If the operations has been pre-approved by the protector, the signature should be replaced
   * by a shorter (invalid) one, to tell the signature validator to look for a pre-approval.
   */
  function setProtector(
    address protector_,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  /**
   * @dev Imports protectors and safe recipients from another tokenId owned by the same owner
   * It requires that there are no protectors and no safe recipients in the current token, and
   * that the origin token has at least one protector or one safe recipient.
   */
  function importProtectorsAndSafeRecipientsFrom(uint256 tokenId) external;

  /**
   * @dev get the list of all protectors
   */
  function getProtectors() external view returns (address[] memory);

  /**
   * @dev Set a safe recipient for the token, i.e., an address that can receive the token without any restriction
   * even when protectors have been set.
   * @param recipient The recipient address
   * @param status True to add a safe recipient, false to remove it
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the protector
   */
  function setSafeRecipient(
    address recipient,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  /**
   * @dev Check if an address is a safe recipient
   * @param recipient The recipient address
   * @return True if the recipient is a safe recipient
   */
  function isSafeRecipient(address recipient) external view returns (bool);

  /**
   * @dev Gets all safe recipients
   * @return An array with the list of all safe recipients
   */
  function getSafeRecipients() external view returns (address[] memory);

  /**
   * @dev It plugs a new plugin
   * @param key The key of the plugin
   * @param canManageTransfer True if the plugin can manage transfers
   * @param isERC6551Account True if the plugin is an ERC6551 account
   * @param data The data to be used during the initialization of the plugin
   * Notice that data cannot be verified by the Manager since they are used by the plugin
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the protector
   */
  function plug(
    bytes32 key,
    bool canManageTransfer,
    bool isERC6551Account,
    bytes memory data,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  /**
   * @dev It changes the status of a plugin
   * @param key The key of the plugin
   * @param change The type of change
   * @param timeLock_ The time lock for when a plugin is temporarily unauthorized from making transfers
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the protector
   */
  function changePluginStatus(
    bytes32 key,
    PluginChange change,
    uint256 timeLock_,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  /**
   * @dev It trusts a plugin
   * @param key The key of the plugin
   * No need for a signature by a protector because the safety of the plugin is
   * guaranteed by the CrunaGuardian.
   */
  function trustPlugin(bytes32 key) external;

  /**
   * @dev It returns the address of a plugin
   * @param key The key of the plugin
   * The address is returned even if a plugin has not deployed yet.
   * @return The plugin address
   */
  function pluginAddress(bytes32 key) external view returns (address payable);

  /**
   * @dev It returns a plugin by name and salt
   * @param key The key of the plugin
   * The plugin is returned even if a plugin has not deployed yet, which means that it will
   * revert during the execution.
   * @return The plugin
   */
  function plugin(bytes32 key) external view returns (CrunaManagedService);

  /**
   * @dev It returns the number of services
   */
  function countPlugins() external view returns (uint256, uint256);

  /**
   * @dev Says if a plugin is currently plugged
   * @param key The key of the plugin
   */
  function plugged(bytes32 key) external view returns (bool);

  /**
   * @dev Returns the index of a plugin
   * @param key The key of the plugin
   * @return a tuple with a true if the plugin is found, and the index of the plugin
   */
  function pluginIndex(bytes32 key) external view returns (bool, uint256);

  /**
   * @dev Checks if a plugin is active
   * @param key The key of the plugin
   * @return True if the plugin is active
   */
  function isPluginActive(bytes32 key) external view returns (bool);

  /**
   * @dev returns the list of services' keys
   * Since the names of the services are not saved in the contract, the app calling for this function
   * is responsible for knowing the names of all the services.
   * In the future it would be good to have an official registry of all services to be able to reverse
   * from the nameId to the name as a string.
   * @param active True to get the list of active services, false to get the list of inactive services
   * @return The list of services' keys
   */
  function listPluginsKeys(bool active) external view returns (bytes32[] memory);

  /**
   * @dev It returns a pseudo address created from the name of a plugin and the salt used to deploy it.
   * Notice that abi.encodePacked does not risk to create collisions because the salt has fixed length
   * in the hashed bytes.
   * @param key The key of the plugin
   * @return The pseudo address of the plugin
   */
  function pseudoAddress(bytes32 key) external view returns (address);

  /**
   * @dev A special function that can be called only by authorized services to transfer the NFT.
   * @param key The key of the plugin
   * @param to The address of the recipient
   */
  function managedTransfer(bytes32 key, address to) external;

  /**
   * @dev Allows the user to transfer the NFT when protectors are set
   * @param tokenId The id of the token
   * @param to The address of the recipient
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the protector
   * The function should revert if no protectors are set, inviting to use the standard
   * ERC721 transfer functions.
   */
  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  /**
   * @dev Upgrades the implementation of the manager
   * @param implementation_ The address of the new implementation
   */
  function upgrade(address implementation_) external;
}
