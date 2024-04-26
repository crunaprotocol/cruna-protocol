# Solidity API

## ICrunaManager

### PluginConfig

A struct to keep info about plugged and unplugged services

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
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
```

### PluginElement

The plugin element

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
struct PluginElement {
  bytes4 nameId;
  bytes4 salt;
  bool active;
}
```

### PluginChange

It enumerates the action that can be performed when changing the status of a plugin

```solidity
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
```

### EmitLockedEventFailed

```solidity
event EmitLockedEventFailed()
```

Event emitted when the manager call to the NFT to emit a Locked event fails.

### ProtectorChange

```solidity
event ProtectorChange(address protector, bool status)
```

Event emitted when the `status` of `protector` changes

### ProtectorsAndSafeRecipientsImported

```solidity
event ProtectorsAndSafeRecipientsImported(address[] protectors, address[] safeRecipients, uint256 fromTokenId)
```

Event emitted when protectors and safe recipients are imported from another token

### SafeRecipientChange

```solidity
event SafeRecipientChange(address recipient, bool status)
```

Event emitted when the `status` of `recipient` changes

### PluginStatusChange

```solidity
event PluginStatusChange(string name, bytes4 salt, address pluginAddress, uint256 change)
```

Event emitted when
the status of plugin identified by `name` and `salt`, and deployed to `pluginAddress` gets a specific `change`

### Reset

```solidity
event Reset()
```

Emitted when protectors and safe recipients are removed and all services are disabled (if they require it)
This event overrides any specific ProtectorChange, SafeRecipientChange and PluginStatusChange event

### PluginTrusted

```solidity
event PluginTrusted(string name, bytes4 salt)
```

Emitted when a plugin initially plugged despite being not trusted, is trusted by the CrunaGuardian

### ImplementationUpgraded

```solidity
event ImplementationUpgraded(address implementation_, uint256 oldVersion, uint256 newVersion)
```

Emitted when the implementation of the manager is upgraded

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation_ | address | The address of the new implementation |
| oldVersion | uint256 | The old version of the manager |
| newVersion | uint256 | The new version of the manager |

### PluginResetAttemptFailed

```solidity
event PluginResetAttemptFailed(bytes4 _nameId, bytes4 salt)
```

Event emitted when the attempt to reset a plugin fails
When this happens, the token owner can unplug the plugin and mark it as banned to avoid future re-plugs

### UntrustedImplementation

```solidity
error UntrustedImplementation(address implementation)
```

Returned when trying to upgrade the manager to an untrusted implementation

### InvalidVersion

```solidity
error InvalidVersion(uint256 oldVersion, uint256 newVersion)
```

Returned when trying to upgrade to an older version of the manager

### PluginRequiresUpdatedManager

```solidity
error PluginRequiresUpdatedManager(uint256 requiredVersion)
```

Returned when trying to plug a plugin that requires a new version of the manager

### Forbidden

```solidity
error Forbidden()
```

Returned when the sender has no right to execute a function

### NotAManager

```solidity
error NotAManager(address sender)
```

Returned when the sender is not a manager

### ProtectorNotFound

```solidity
error ProtectorNotFound(address protector)
```

Returned when a protector is not found

### ProtectorAlreadySetByYou

```solidity
error ProtectorAlreadySetByYou(address protector)
```

Returned when a protector is already set by the sender

### ProtectorsAlreadySet

```solidity
error ProtectorsAlreadySet()
```

Returned when a protector is already set

### CannotBeYourself

```solidity
error CannotBeYourself()
```

Returned when trying to set themself as a protector

### NotTheAuthorizedPlugin

```solidity
error NotTheAuthorizedPlugin(address callingPlugin)
```

Returned when the managed transfer is called not by the right plugin

### UnmanagedService

```solidity
error UnmanagedService()
```

Returned when the pluggin service is not a managed service

### PluginNumberOverflow

```solidity
error PluginNumberOverflow()
```

Returned when there is no more space for services

### PluginHasBeenMarkedAsNotPluggable

```solidity
error PluginHasBeenMarkedAsNotPluggable()
```

Returned when the plugin has been banned and marked as not pluggable

### PluginAlreadyPlugged

```solidity
error PluginAlreadyPlugged()
```

Returned when a plugin has already been plugged

### PluginNotFound

```solidity
error PluginNotFound()
```

Returned when a plugin is not found

### InconsistentProxyAddresses

```solidity
error InconsistentProxyAddresses(address currentAddress, address proposedAddress)
```

Returned when trying to plug an unplugged plugin and the address of the implementation differ

### PluginNotFoundOrDisabled

```solidity
error PluginNotFoundOrDisabled()
```

Returned when a plugin is not found or is disabled

### PluginNotDisabled

```solidity
error PluginNotDisabled()
```

_Returned when tryng to re-enable a not-disabled plugin_

### PluginAlreadyDisabled

```solidity
error PluginAlreadyDisabled()
```

_Returned when trying to disable a plugin that is already disabled_

### PluginNotAuthorizedToManageTransfer

```solidity
error PluginNotAuthorizedToManageTransfer()
```

_Returned when a plugin tries to transfer the NFT without authorization_

### PluginAlreadyAuthorized

```solidity
error PluginAlreadyAuthorized()
```

_Returned when a plugin has already been authorized_

### PluginAlreadyUnauthorized

```solidity
error PluginAlreadyUnauthorized()
```

_Returned when a plugin has already been unauthorized_

### NotATransferPlugin

```solidity
error NotATransferPlugin()
```

_Returned when a plugin is not authorized to make transfers_

### InvalidImplementation

```solidity
error InvalidImplementation(bytes4 nameIdReturnedByPlugin, bytes4 proposedNameId)
```

_Returned when trying to plug a plugin that responds to a different nameId_

### InvalidTimeLock

```solidity
error InvalidTimeLock(uint256 timeLock)
```

_Returned when setting an invalid TimeLock when temporarily de-authorizing a plugin_

### InvalidValidity

```solidity
error InvalidValidity()
```

_Returned when calling a function with a validity overflowing the maximum value_

### InvalidERC6551Status

```solidity
error InvalidERC6551Status()
```

_Returned when plugging plugin as ERC6551 while the plugin is not an ERC6551 account, or vice versa_

### UntrustedImplementationsNotAllowedToMakeTransfers

```solidity
error UntrustedImplementationsNotAllowedToMakeTransfers()
```

_Returned when trying to make a transfer with an untrusted plugin, when the NFT accepts only trusted ones_

### StillUntrusted

```solidity
error StillUntrusted()
```

_Returned if trying to trust a plugin that is still untrusted_

### PluginAlreadyTrusted

```solidity
error PluginAlreadyTrusted()
```

_Returned if a plugin has already been trusted_

### CannotImportProtectorsAndSafeRecipientsFromYourself

```solidity
error CannotImportProtectorsAndSafeRecipientsFromYourself()
```

_Returned when trying to import protectors and safe recipients from the token itself_

### NotTheSameOwner

```solidity
error NotTheSameOwner(address originSOwner, address owner)
```

_Returned when the owner of the exporter token is different from the owner of the importer token_

### SafeRecipientsAlreadySet

```solidity
error SafeRecipientsAlreadySet()
```

_Returned when some safe recipients have already been set_

### NothingToImport

```solidity
error NothingToImport()
```

_Returned when the origin token has no protectors and no safe recipients_

### UnsupportedPluginChange

```solidity
error UnsupportedPluginChange()
```

_Returned when trying to change the status of a plugin to an unsupported mode_

### IndexOutOfBounds

```solidity
error IndexOutOfBounds()
```

_Returned when trying to get the index of a plugin in the allPlugins array, but that index is out of bounds_

### ToBeUsedOnlyWhenProtectorsAreActive

```solidity
error ToBeUsedOnlyWhenProtectorsAreActive()
```

_Returned when trying to use a function that requires protectors, but no protectors are set_

### pluginByKey

```solidity
function pluginByKey(bytes8 key) external view returns (struct ICrunaManager.PluginConfig)
```

_It returns the configuration of a plugin by key_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| key | bytes8 | The key of the plugin |

### allPlugins

```solidity
function allPlugins() external view returns (struct ICrunaManager.PluginElement[])
```

_It returns the configuration of all currently plugged services_

### pluginByIndex

```solidity
function pluginByIndex(uint256 index) external view returns (struct ICrunaManager.PluginElement)
```

_It returns an element of the array of all plugged services_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | The index of the plugin in the array |

### migrate

```solidity
function migrate(uint256) external
```

_During an upgrade allows the manager to perform adjustments if necessary.
The parameter is the version of the manager being replaced. This will allow the
new manager to know what to do to adjust the state of the new manager._

### findProtectorIndex

```solidity
function findProtectorIndex(address protector_) external view returns (uint256)
```

_Find a specific protector_

### isProtector

```solidity
function isProtector(address protector_) external view returns (bool)
```

_Returns true if the address is a protector._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protector_ | address | The protector address. |

### hasProtectors

```solidity
function hasProtectors() external view returns (bool)
```

_Returns true if there are protectors._

### isTransferable

```solidity
function isTransferable(address to) external view returns (bool)
```

_Returns true if the token is transferable (since the NFT is ERC6454)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of the recipient. If the recipient is a safe recipient, it returns true. |

### locked

```solidity
function locked() external view returns (bool)
```

_Returns true if the token is locked (since the NFT is ERC6982)_

### countProtectors

```solidity
function countProtectors() external view returns (uint256)
```

_Counts how many protectors have been set_

### countSafeRecipients

```solidity
function countSafeRecipients() external view returns (uint256)
```

_Counts the safe recipients_

### setProtector

```solidity
function setProtector(address protector_, bool status, uint256 timestamp, uint256 validFor, bytes signature) external
```

_Set a protector for the token_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protector_ | address | The protector address |
| status | bool | True to add a protector, false to remove it |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the protector If no signature is required, the field timestamp must be 0 If the operations has been pre-approved by the protector, the signature should be replaced by a shorter (invalid) one, to tell the signature validator to look for a pre-approval. |

### importProtectorsAndSafeRecipientsFrom

```solidity
function importProtectorsAndSafeRecipientsFrom(uint256 tokenId) external
```

_Imports protectors and safe recipients from another tokenId owned by the same owner
It requires that there are no protectors and no safe recipients in the current token, and
that the origin token has at least one protector or one safe recipient._

### getProtectors

```solidity
function getProtectors() external view returns (address[])
```

_get the list of all protectors_

### setSafeRecipient

```solidity
function setSafeRecipient(address recipient, bool status, uint256 timestamp, uint256 validFor, bytes signature) external
```

_Set a safe recipient for the token, i.e., an address that can receive the token without any restriction
even when protectors have been set._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The recipient address |
| status | bool | True to add a safe recipient, false to remove it |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the protector |

### isSafeRecipient

```solidity
function isSafeRecipient(address recipient) external view returns (bool)
```

_Check if an address is a safe recipient_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The recipient address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the recipient is a safe recipient |

### getSafeRecipients

```solidity
function getSafeRecipients() external view returns (address[])
```

_Gets all safe recipients_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | An array with the list of all safe recipients |

### plug

```solidity
function plug(string name, address pluginProxy, bool canManageTransfer, bool isERC6551Account, bytes4 salt, bytes data, uint256 timestamp, uint256 validFor, bytes signature) external
```

_It plugs a new plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| pluginProxy | address | The address of the plugin implementation |
| canManageTransfer | bool | True if the plugin can manage transfers |
| isERC6551Account | bool | True if the plugin is an ERC6551 account |
| salt | bytes4 | The salt used during the deployment of the plugin |
| data | bytes | The data to be used during the initialization of the plugin Notice that data cannot be verified by the Manager since they are used by the plugin |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the protector |

### changePluginStatus

```solidity
function changePluginStatus(string name, bytes4 salt, enum ICrunaManager.PluginChange change, uint256 timeLock_, uint256 timestamp, uint256 validFor, bytes signature) external
```

_It changes the status of a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin |
| change | enum ICrunaManager.PluginChange | The type of change |
| timeLock_ | uint256 | The time lock for when a plugin is temporarily unauthorized from making transfers |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the protector |

### trustPlugin

```solidity
function trustPlugin(string name, bytes4 salt) external
```

_It trusts a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin No need for a signature by a protector because the safety of the plugin is guaranteed by the CrunaGuardian. |

### pluginAddress

```solidity
function pluginAddress(bytes4 nameId_, bytes4 salt) external view returns (address payable)
```

_It returns the address of a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId_ | bytes4 | The bytes4 of the hash of the name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin The address is returned even if a plugin has not deployed yet. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address payable | The plugin address |

### plugin

```solidity
function plugin(bytes4 nameId_, bytes4 salt) external view returns (contract CrunaManagedService)
```

_It returns a plugin by name and salt_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId_ | bytes4 | The bytes4 of the hash of the name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin The plugin is returned even if a plugin has not deployed yet, which means that it will revert during the execution. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract CrunaManagedService | The plugin |

### countPlugins

```solidity
function countPlugins() external view returns (uint256, uint256)
```

_It returns the number of services_

### plugged

```solidity
function plugged(string name, bytes4 salt) external view returns (bool)
```

_Says if a plugin is currently plugged_

### pluginIndex

```solidity
function pluginIndex(string name, bytes4 salt) external view returns (bool, uint256)
```

_Returns the index of a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | a tuple with a true if the plugin is found, and the index of the plugin |
| [1] | uint256 |  |

### isPluginActive

```solidity
function isPluginActive(string name, bytes4 salt) external view returns (bool)
```

_Checks if a plugin is active_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the plugin is active |

### listPluginsKeys

```solidity
function listPluginsKeys(bool active) external view returns (bytes8[])
```

_returns the list of services' keys
Since the names of the services are not saved in the contract, the app calling for this function
is responsible for knowing the names of all the services.
In the future it would be good to have an official registry of all services to be able to reverse
from the nameId to the name as a string._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| active | bool | True to get the list of active services, false to get the list of inactive services |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes8[] | The list of services' keys |

### pseudoAddress

```solidity
function pseudoAddress(string name, bytes4 _salt) external view returns (address)
```

_It returns a pseudo address created from the name of a plugin and the salt used to deploy it.
Notice that abi.encodePacked does not risk to create collisions because the salt has fixed length
in the hashed bytes._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| _salt | bytes4 | The salt used during the deployment of the plugin |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The pseudo address of the plugin |

### managedTransfer

```solidity
function managedTransfer(bytes4 pluginNameId, address to) external
```

_A special function that can be called only by authorized services to transfer the NFT._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pluginNameId | bytes4 | The bytes4 of the hash of the name of the plugin The plugin must be searched by the pluginNameId and the salt, and the function must verify that the current sender is the plugin. |
| to | address | The address of the recipient |

### protectedTransfer

```solidity
function protectedTransfer(uint256 tokenId, address to, uint256 timestamp, uint256 validFor, bytes signature) external
```

_Allows the user to transfer the NFT when protectors are set_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The id of the token |
| to | address | The address of the recipient |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the protector The function should revert if no protectors are set, inviting to use the standard ERC721 transfer functions. |

### upgrade

```solidity
function upgrade(address implementation_) external
```

_Upgrades the implementation of the manager_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation_ | address | The address of the new implementation |

