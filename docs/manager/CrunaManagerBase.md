# Solidity API

## CrunaManagerBase

Base contract for managers and plugins

### _IMPLEMENTATION_SLOT

```solidity
bytes32 _IMPLEMENTATION_SLOT
```

Storage slot with the address of the current implementation.
This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
validated in the constructor.

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

