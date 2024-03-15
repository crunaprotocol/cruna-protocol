# Solidity API

## ICrunaPlugin

Interface for plugins

_Technically, plugins are secondary managers, pluggable in
the primary manage, which is CrunaManager.sol_

### Conf

The configuration of the plugin

```solidity
struct Conf {
  contract CrunaManager manager;
  uint32 mustBeReset;
}
```

### UntrustedImplementation

```solidity
error UntrustedImplementation(address implementation)
```

Error returned when the plugin is reset

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the new implementation |

### InvalidVersion

```solidity
error InvalidVersion(uint256 oldVersion, uint256 newVersion)
```

Error returned when the plugin is reset

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| oldVersion | uint256 | The version of the current implementation |
| newVersion | uint256 | The version of the new implementation |

### PluginRequiresUpdatedManager

```solidity
error PluginRequiresUpdatedManager(uint256 requiredVersion)
```

Error returned when the plugin is reset

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| requiredVersion | uint256 | The version required by the plugin |

### Forbidden

```solidity
error Forbidden()
```

Error returned when the plugin is reset

### PluginMustBeReset

```solidity
error PluginMustBeReset()
```

Error returned when the plugin must be reset before using it

### init

```solidity
function init() external
```

Initialize the plugin. It must be implemented, but can do nothing is no init is needed.

### requiresToManageTransfer

```solidity
function requiresToManageTransfer() external pure returns (bool)
```

Called by the manager during the plugging to know if the plugin is asking the
right to make a managed transfer of the vault

### requiresResetOnTransfer

```solidity
function requiresResetOnTransfer() external pure returns (bool)
```

Called by the manager to know it the plugin must be reset when transferring the NFT

### isERC6551Account

```solidity
function isERC6551Account() external pure returns (bool)
```

Called by the manager to know if the plugin is an ERC721 account

### reset

```solidity
function reset() external
```

Reset the plugin to the factory settings

### resetOnTransfer

```solidity
function resetOnTransfer() external
```

### upgrade

```solidity
function upgrade(address implementation_) external
```

Upgrade the implementation of the manager/plugin
Notice that the owner can upgrade active or disable plugins
so that, if a plugin is compromised, the user can disable it,
wait for a new trusted implementation and upgrade it.

### manager

```solidity
function manager() external view returns (contract CrunaManager)
```

Returns the manager

