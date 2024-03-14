# Solidity API

## CrunaManagerBase

Base contract for managers and plugins

### upgrade

```solidity
function upgrade(address implementation_) external virtual
```

Upgrade the implementation of the manager

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation_ | address | The new implementation |

### migrate

```solidity
function migrate(uint256 previousVersion) external virtual
```

Execute actions needed in a new manager based on the previous version

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| previousVersion | uint256 | The previous version |

### _version

```solidity
function _version() internal pure virtual returns (uint256)
```

