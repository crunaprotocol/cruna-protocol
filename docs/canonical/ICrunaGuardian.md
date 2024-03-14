# Solidity API

## ICrunaGuardian

_Manages upgrade and cross-chain execution settings for accounts_

### TrustedImplementationUpdated

```solidity
event TrustedImplementationUpdated(bytes4 nameId, address implementation, bool trusted, uint256 requires)
```

_Emitted when a trusted implementation is updated_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId | bytes4 | The bytes4 nameId of the implementation |
| implementation | address | The address of the implementation |
| trusted | bool | Whether the implementation is marked as a trusted or marked as no more trusted |
| requires | uint256 | The version of the manager required by the implementation |

### setTrustedImplementation

```solidity
function setTrustedImplementation(bytes4 nameId, address implementation, bool trusted, uint256 requires) external
```

_Sets a given implementation address as trusted, allowing accounts to upgrade to this implementation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId | bytes4 | The bytes4 nameId of the implementation |
| implementation | address | The address of the implementation |
| trusted | bool | When true, it set the implementation as trusted, when false it removes the implementation from the trusted list |
| requires | uint256 | The version of the manager required by the implementation (for plugins) Notice that for managers requires will always be 1 |

### trustedImplementation

```solidity
function trustedImplementation(bytes4 nameId, address implementation) external view returns (uint256)
```

_Returns the manager version required by a trusted implementation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId | bytes4 | The bytes4 nameId of the implementation |
| implementation | address | The address of the implementation |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The version of the manager required by a trusted implementation. If it is 0, it means the implementation is not trusted |

