# Solidity API

## CrunaManager

The manager of the Cruna NFT
It is the only contract that can manage the NFT. It sets protectors and safe recipients,
plugs and manages plugins, and has the ability to transfer the NFT if there are protectors.

### version

```solidity
function version() external pure virtual returns (uint256)
```

see {IVersioned-version}

### pluginByKey

```solidity
function pluginByKey(bytes8 key) external view returns (struct ICrunaManager.PluginConfig)
```

see {ICrunaManager-getPluginByKey}

### allPlugins

```solidity
function allPlugins() external view returns (struct ICrunaManager.PluginElement[])
```

see {ICrunaManager-allPlugins}

### pluginByIndex

```solidity
function pluginByIndex(uint256 index) external view returns (struct ICrunaManager.PluginElement)
```

see {ICrunaManager-pluginByIndex}

### migrate

```solidity
function migrate(uint256) external virtual
```

see {ICrunaManager-migrate}

### findProtectorIndex

```solidity
function findProtectorIndex(address protector_) external view virtual returns (uint256)
```

see {ICrunaManager-findProtectorIndex}

### isProtector

```solidity
function isProtector(address protector_) external view virtual returns (bool)
```

see {ICrunaManager-isProtector}

### hasProtectors

```solidity
function hasProtectors() external view virtual returns (bool)
```

see {ICrunaManager-hasProtectors}

### isTransferable

```solidity
function isTransferable(address to) external view returns (bool)
```

see {ICrunaManager-isTransferable}

### locked

```solidity
function locked() external view returns (bool)
```

see {ICrunaManager-locked}

### countProtectors

```solidity
function countProtectors() external view virtual returns (uint256)
```

see {ICrunaManager-countProtectors}

### countSafeRecipients

```solidity
function countSafeRecipients() external view virtual returns (uint256)
```

see {ICrunaManager-countSafeRecipients}

### setProtector

```solidity
function setProtector(address protector_, bool status, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

see {ICrunaManager-setProtector}

### importProtectorsAndSafeRecipientsFrom

```solidity
function importProtectorsAndSafeRecipientsFrom(uint256 otherTokenId) external virtual
```

see {ICrunaManager-importProtectorsAndSafeRecipientsFrom}

### getProtectors

```solidity
function getProtectors() external view virtual returns (address[])
```

see {ICrunaManager-getProtectors}

### setSafeRecipient

```solidity
function setSafeRecipient(address recipient, bool status, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

see {ICrunaManager-setSafeRecipient}

### isSafeRecipient

```solidity
function isSafeRecipient(address recipient) external view virtual returns (bool)
```

see {ICrunaManager-isSafeRecipient}

### getSafeRecipients

```solidity
function getSafeRecipients() external view virtual returns (address[])
```

see {ICrunaManager-getSafeRecipients}

### plug

```solidity
function plug(string name, address proxyAddress_, bool canManageTransfer, bool isERC6551Account, bytes4 salt, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

see {ICrunaManager-plug}

### changePluginStatus

```solidity
function changePluginStatus(string name, bytes4 salt, enum ICrunaManager.PluginChange change, uint256 timeLock_, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

see {ICrunaManager-changePluginStatus}

### trustPlugin

```solidity
function trustPlugin(string name, bytes4 salt) external virtual
```

see {ICrunaManager-trustPlugin}

### pluginAddress

```solidity
function pluginAddress(bytes4 nameId_, bytes4 salt) external view virtual returns (address payable)
```

see {ICrunaManager-countPlugins}

### plugin

```solidity
function plugin(bytes4 nameId_, bytes4 salt) external view virtual returns (contract CrunaPluginBase)
```

see {ICrunaManager-plugin}

### countPlugins

```solidity
function countPlugins() external view virtual returns (uint256, uint256)
```

see {ICrunaManager-countPlugins}

### plugged

```solidity
function plugged(string name, bytes4 salt) external view virtual returns (bool)
```

see {ICrunaManager-plugged}

### pluginIndex

```solidity
function pluginIndex(string name, bytes4 salt) external view virtual returns (bool, uint256)
```

see {ICrunaManager-pluginIndex}

### isPluginActive

```solidity
function isPluginActive(string name, bytes4 salt) external view virtual returns (bool)
```

see {ICrunaManager-disablePlugin}

### listPluginsKeys

```solidity
function listPluginsKeys(bool active) external view virtual returns (bytes8[])
```

see {ICrunaManager-listPluginsKeys}

### pseudoAddress

```solidity
function pseudoAddress(string name, bytes4 _salt) external view virtual returns (address)
```

see {ICrunaManager-pseudoAddress}

### managedTransfer

```solidity
function managedTransfer(bytes4 pluginNameId, address to) external virtual
```

see {IProtected721-managedTransfer}.

### protectedTransfer

```solidity
function protectedTransfer(uint256 tokenId, address to, uint256 timestamp, uint256 validFor, bytes signature) external
```

see {IProtected721-protectedTransfer}.

### _plugin

```solidity
function _plugin(bytes4 nameId_, bytes4 salt) internal view virtual returns (contract CrunaPluginBase)
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

Counts the active and disabled plugins

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
the NFT. If the plugins must be blocked for more time, disable it at your peril of making it useless.

### _combineBytes4

```solidity
function _combineBytes4(bytes4 a, bytes4 b) internal pure returns (bytes8)
```

Utility function to combine two bytes4 into a bytes8

### _isProtected

```solidity
function _isProtected() internal view virtual returns (bool)
```

Check if the NFT is protected

### _isProtector

```solidity
function _isProtector(address protector_) internal view virtual returns (bool)
```

Checks if an address is a protector

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protector_ | address | The address to check |

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
function _plug(string name, address proxyAddress_, bool canManageTransfer, bool isERC6551Account, bytes4 nameId_, bytes4 salt, bytes8 _key, uint256 requires) internal
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
| _key | bytes8 | The key of the plugin |
| requires | uint256 | The version of the manager required by the implementation |

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

