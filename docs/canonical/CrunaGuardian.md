# Solidity API

## CrunaGuardian

Manages a registry of trusted implementations and their required manager versions

It is used by
- manager and plugins to upgrade its own  implementation
- manager to trust a new plugin implementation and allow managed transfers

### InvalidArguments

```solidity
error InvalidArguments()
```

Error returned when the arguments are invalid

### constructor

```solidity
constructor(uint256 minDelay, address[] proposers, address[] executors, address admin) public
```

When deployed to production, proposers and executors will be multi-sig wallets owned by the Cruna DAO

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minDelay | uint256 | The minimum delay for timelock operations |
| proposers | address[] | The addresses that can propose timelock operations |
| executors | address[] | The addresses that can execute timelock operations |
| admin | address | The address that can admin the contract. It will renounce to the role, as soon as the  DAO is stable and there are no risks in doing so. |

### version

```solidity
function version() external pure virtual returns (uint256)
```

see {ICrunaGuardian-setTrustedImplementation}

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
