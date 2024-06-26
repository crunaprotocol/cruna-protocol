# Solidity API

## ICrunaGuardian

Manages upgrade and cross-chain execution settings for accounts

### Trusted

```solidity
event Trusted(address implementation, bool trusted)
```

Emitted when a trusted implementation is updated

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the implementation |
| trusted | bool | Whether the implementation is marked as a trusted or marked as no more trusted |

### trust

```solidity
function trust(uint256 delay, enum ITimeControlledGovernance.OperationType oType, address implementation, bool trusted) external
```

Sets a given implementation address as trusted, allowing accounts to upgrade to this implementation.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| delay | uint256 | The delay for the operation |
| oType | enum ITimeControlledGovernance.OperationType | The type of operation |
| implementation | address | The address of the implementation |
| trusted | bool | When true, it set the implementation as trusted, when false it removes the implementation from the trusted list Notice that for managers requires will always be 1 |

### trusted

```solidity
function trusted(address implementation) external view returns (bool)
```

Returns the manager version required by a trusted implementation

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the implementation |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if a trusted implementation |

