# Solidity API

## ICrunaPlugin

_Interface for plugins
Technically, plugins are secondary managers, pluggable in
the primary manage, which is CrunaManager.sol_

### Conf

_The configuration of the plugin_

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

_Error returned when the plugin is reset_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the new implementation |

### InvalidVersion

```solidity
error InvalidVersion(uint256 oldVersion, uint256 newVersion)
```

_Error returned when the plugin is reset_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| oldVersion | uint256 | The version of the current implementation |
| newVersion | uint256 | The version of the new implementation |

### PluginRequiresUpdatedManager

```solidity
error PluginRequiresUpdatedManager(uint256 requiredVersion)
```

_Error returned when the plugin is reset_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| requiredVersion | uint256 | The version required by the plugin |

### Forbidden

```solidity
error Forbidden()
```

_Error returned when the plugin is reset_

### PluginMustBeReset

```solidity
error PluginMustBeReset()
```

_Error returned when the plugin must be reset before using it_

### init

```solidity
function init() external
```

_Initialize the plugin. It must be implemented, but can do nothing is no init is needed._

### requiresToManageTransfer

```solidity
function requiresToManageTransfer() external pure returns (bool)
```

_Called by the manager during the plugging to know if the plugin is asking the
right to make a managed transfer of the vault_

### requiresResetOnTransfer

```solidity
function requiresResetOnTransfer() external pure returns (bool)
```

_Called by the manager to know it the plugin must be reset when transferring the NFT_

### isERC6551Account

```solidity
function isERC6551Account() external pure returns (bool)
```

_Called by the manager to know if the plugin is an ERC721 account_

### reset

```solidity
function reset() external
```

_Reset the plugin to the factory settings_

### resetOnTransfer

```solidity
function resetOnTransfer() external
```

### upgrade

```solidity
function upgrade(address implementation_) external
```

_Upgrade the implementation of the manager/plugin
Notice that the owner can upgrade active or disable plugins
so that, if a plugin is compromised, the user can disable it,
wait for a new trusted implementation and upgrade it._

### manager

```solidity
function manager() external view returns (contract CrunaManager)
```

_Returns the manager_

