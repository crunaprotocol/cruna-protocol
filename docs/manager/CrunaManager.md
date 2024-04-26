# Solidity API

## CrunaManager

The manager of the Cruna NFT
It is the only contract that can manage the NFT. It sets protectors and safe recipients,
plugs and manages services, and has the ability to transfer the NFT if there are protectors.

### version

```solidity
function version() external pure virtual returns (uint256)
```

Returns the version of the contract.
The format is similar to semver, where any element takes 3 digits.
For example, version 1.2.14 is 1_002_014.

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
function migrate(uint256) external virtual
```

_During an upgrade allows the manager to perform adjustments if necessary.
The parameter is the version of the manager being replaced. This will allow the
new manager to know what to do to adjust the state of the new manager._

### findProtectorIndex

```solidity
function findProtectorIndex(address protector_) external view virtual returns (uint256)
```

_Find a specific protector_

### isProtector

```solidity
function isProtector(address protector_) external view virtual returns (bool)
```

_Returns true if the address is a protector._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protector_ | address | The protector address. |

### hasProtectors

```solidity
function hasProtectors() external view virtual returns (bool)
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
function countProtectors() external view virtual returns (uint256)
```

_Counts how many protectors have been set_

### countSafeRecipients

```solidity
function countSafeRecipients() external view virtual returns (uint256)
```

_Counts the safe recipients_

### setProtector

```solidity
function setProtector(address protector_, bool status, uint256 timestamp, uint256 validFor, bytes signature) external virtual
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
function importProtectorsAndSafeRecipientsFrom(uint256 otherTokenId) external virtual
```

_Imports protectors and safe recipients from another tokenId owned by the same owner
It requires that there are no protectors and no safe recipients in the current token, and
that the origin token has at least one protector or one safe recipient._

### getProtectors

```solidity
function getProtectors() external view virtual returns (address[])
```

_get the list of all protectors_

### setSafeRecipient

```solidity
function setSafeRecipient(address recipient, bool status, uint256 timestamp, uint256 validFor, bytes signature) external virtual
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
function isSafeRecipient(address recipient) external view virtual returns (bool)
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
function getSafeRecipients() external view virtual returns (address[])
```

_Gets all safe recipients_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | An array with the list of all safe recipients |

### plug

```solidity
function plug(string name, address pluginProxy, bool canManageTransfer, bool isERC6551Account, bytes4 salt, bytes data, uint256 timestamp, uint256 validFor, bytes signature) external virtual
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
function changePluginStatus(string name, bytes4 salt, enum ICrunaManager.PluginChange change, uint256 timeLock_, uint256 timestamp, uint256 validFor, bytes signature) external virtual
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
function trustPlugin(string name, bytes4 salt) external virtual
```

_It trusts a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin No need for a signature by a protector because the safety of the plugin is guaranteed by the CrunaGuardian. |

### pluginAddress

```solidity
function pluginAddress(bytes4 nameId_, bytes4 salt) external view virtual returns (address payable)
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
function plugin(bytes4 nameId_, bytes4 salt) external view virtual returns (contract CrunaManagedService)
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
function countPlugins() external view virtual returns (uint256, uint256)
```

_It returns the number of services_

### plugged

```solidity
function plugged(string name, bytes4 salt) external view virtual returns (bool)
```

_Says if a plugin is currently plugged_

### pluginIndex

```solidity
function pluginIndex(string name, bytes4 salt) external view virtual returns (bool, uint256)
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
function isPluginActive(string name, bytes4 salt) external view virtual returns (bool)
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
function listPluginsKeys(bool active) external view virtual returns (bytes8[])
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
function pseudoAddress(string name, bytes4 _salt) external view virtual returns (address)
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
function managedTransfer(bytes4 pluginNameId, address to) external virtual
```

see {IProtectedNFT-managedTransfer}.

### protectedTransfer

```solidity
function protectedTransfer(uint256 tokenId_, address to, uint256 timestamp, uint256 validFor, bytes signature) external
```

see {IProtectedNFT-protectedTransfer}.

### _plugin

```solidity
function _plugin(bytes4 nameId_, bytes4 salt) internal view virtual returns (contract CrunaManagedService)
```

### _pluginAddress

```solidity
function _pluginAddress(bytes4 nameId_, bytes4 salt) internal view virtual returns (address payable)
```

returns the address of a deployed plugin

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId_ | bytes4 | The nameId of the plugin |
| salt | bytes4 | The salt of the plugin |

### _nameId

```solidity
function _nameId() internal view virtual returns (bytes4)
```

returns the name Id of the manager

### _pseudoAddress

```solidity
function _pseudoAddress(string name, bytes4 _salt) internal view virtual returns (address)
```

returns a pseudoaddress composed by the name of the plugin and the salt used
to deploy it. This is needed to pass a valid address as an actor to the SignatureValidator

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| _salt | bytes4 | The salt used to deploy the plugin |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The pseudoaddress |

### _countPlugins

```solidity
function _countPlugins() internal view virtual returns (uint256, uint256)
```

Counts the active and disabled services

### _disablePlugin

```solidity
function _disablePlugin(uint256 i, bytes8 _key) internal
```

Internal function to disable a plugin but index and key

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| i | uint256 | The index of the plugin in the _allPlugins array |
| _key | bytes8 | The key of the plugin |

### _reEnablePlugin

```solidity
function _reEnablePlugin(uint256 i, bytes8 _key) internal
```

Internal function to re-enable a plugin but index and key

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| i | uint256 | The index of the plugin in the _allPlugins array |
| _key | bytes8 | The key of the plugin |

### _unplugPlugin

```solidity
function _unplugPlugin(uint256 i, bytes4 nameId_, bytes4 salt, bytes8 _key, enum ICrunaManager.PluginChange change) internal
```

Unplugs a plugin

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| i | uint256 | The index of the plugin in the _allPlugins array |
| nameId_ | bytes4 | The nameId of the plugin |
| salt | bytes4 | The salt used to deploy the plugin |
| _key | bytes8 | The key of the plugin |
| change | enum ICrunaManager.PluginChange | The change to be made (Unplug or UnplugForever) |

### _authorizePluginToTransfer

```solidity
function _authorizePluginToTransfer(bytes4 nameId_, bytes4 salt, bytes8 _key, enum ICrunaManager.PluginChange change, uint256 timeLock) internal virtual
```

Id removing the authorization, it blocks a plugin for a maximum of 30 days from transferring
the NFT. If the services must be blocked for more time, disable it at your peril of making it useless.

### _canPreApprove

```solidity
function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual returns (bool)
```

Override required by SignatureValidator to check if a signer is authorized to pre-approve an operation

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| selector | bytes4 | The selector of the called function |
| actor | address | The actor to be approved |
| signer | address | The signer of the operation (the protector) |

### _plug

```solidity
function _plug(string name, address proxyAddress_, bool canManageTransfer, bool isERC6551Account, bytes4 nameId_, bytes4 salt, bytes data, bytes8 _key, bool trusted) internal
```

Internal function plug a plugin

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| proxyAddress_ | address | The address of the plugin |
| canManageTransfer | bool | If the plugin can manage the transfer of the NFT |
| isERC6551Account | bool | If the plugin is an ERC6551 account |
| nameId_ | bytes4 | The nameId of the plugin |
| salt | bytes4 | The salt used to deploy the plugin |
| data | bytes | Optional data to be passed to the service |
| _key | bytes8 | The key of the plugin |
| trusted | bool | true if the implementation is trusted |

### _setSignedActor

```solidity
function _setSignedActor(bytes4 _functionSelector, bytes4 role_, address actor, bool status, uint256 timestamp, uint256 validFor, bytes signature, address sender) internal virtual
```

### _emitLockeEvent

```solidity
function _emitLockeEvent(uint256 protectorsCount, bool status) internal virtual
```

It asks the NFT to emit a Locked event, according to IERC6982

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protectorsCount | uint256 | The number of protectors |
| status | bool | If latest protector has been added or removed |

### _getKeyAndSalt

```solidity
function _getKeyAndSalt(bytes4 pluginNameId) internal view returns (bytes8, bytes4)
```

It returns the key and the salt of the current plugin calling the manager

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pluginNameId | bytes4 | The nameId of the plugin |

### _pluginIndex

```solidity
function _pluginIndex(bytes4 nameId_, bytes4 salt) internal view virtual returns (bool, uint256)
```

It returns the index of the plugin in the _allPlugins array

### _preValidateAndCheckSignature

```solidity
function _preValidateAndCheckSignature(bytes4 selector, address actor, uint256 extra, uint256 extra2, uint256 extra3, uint256 timestamp, uint256 validFor, bytes signature) internal virtual
```

Util to validate and check the signature

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| selector | bytes4 | The selector of the function |
| actor | address | The address of the actor (if a protector/safe recipient) or the pseudoAddress of a plugin |
| extra | uint256 | An extra value to be signed |
| extra2 | uint256 | An extra value to be signed |
| extra3 | uint256 | An extra value to be signed |
| timestamp | uint256 | The timestamp of the request |
| validFor | uint256 | The validity of the request |
| signature | bytes | The signature of the request |

### _resetPlugin

```solidity
function _resetPlugin(bytes4 nameId_, bytes4 salt) internal virtual
```

It resets a plugin

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId_ | bytes4 | The nameId of the plugin |
| salt | bytes4 | The salt of the plugin |

### _resetPluginOnTransfer

```solidity
function _resetPluginOnTransfer(bytes4 nameId_, bytes4 salt) internal virtual
```

It resets a plugin on transfer.
It tries to minimize risks and gas consumption limiting the amount of gas sent to
the plugin. Since the called function should not be overridden, it should be safe.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId_ | bytes4 | The nameId of the plugin |
| salt | bytes4 | The salt of the plugin |

### _removeLockIfExpired

```solidity
function _removeLockIfExpired(bytes4 nameId_, bytes4 salt) internal virtual
```

If a plugin has been temporarily deAuthorized from transferring the tolen, it
removes the lock if the lock is expired

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId_ | bytes4 | The nameId of the plugin |
| salt | bytes4 | The salt of the plugin |

### _resetOnTransfer

```solidity
function _resetOnTransfer(bytes4 nameId_, bytes4 salt) internal virtual
```

It resets the manager on transfer

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId_ | bytes4 | The nameId of the plugin calling the transfer |
| salt | bytes4 | The salt of the plugin calling the transfer |

