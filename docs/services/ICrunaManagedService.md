# Solidity API

## ICrunaManagedService

Interface for services

_Technically, services are secondary managers, pluggable in
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

### PluginMustBeReset

```solidity
error PluginMustBeReset()
```

Error returned when the plugin must be reset before using it

### init

```solidity
function init(bytes data) external
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

### requiresManagerVersion

```solidity
function requiresManagerVersion() external pure returns (uint256)
```

Returns the minimum version of the manager required by the plugin

### isERC6551Account

```solidity
function isERC6551Account() external pure returns (bool)
```

Called by the manager to know if the plugin is an ERC721 account

### resetService

```solidity
function resetService() external payable
```

Reset the plugin to the factory settings

### resetOnTransfer

```solidity
function resetOnTransfer() external payable
```

### crunaManager

```solidity
function crunaManager() external view returns (contract CrunaManager)
```

Returns the manager

