# Solidity API

## CrunaGuardian

Manages a registry of trusted implementations and their required manager versions

It is used by
- manager and services to upgrade its own  implementation
- manager to trust a new plugin implementation and allow managed transfers

### InvalidArguments

```solidity
error InvalidArguments()
```

Error returned when the arguments are invalid

### constructor

```solidity
constructor(uint256 minDelay, address firstProposer, address firstExecutor, address admin) public
```

When deployed to production, proposers and executors will be multi-sig wallets owned by the Cruna DAO

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minDelay | uint256 | The minimum delay for time lock operations |
| firstProposer | address | The address that can propose time lock operations |
| firstExecutor | address | The address that can execute time lock operations |
| admin | address | The address that can admin the contract. |

### version

```solidity
function version() external pure virtual returns (uint256)
```

Returns the version of the contract.
The format is similar to semver, where any element takes 3 digits.
For example, version 1.2.14 is 1_002_014.

### trust

```solidity
function trust(uint256 delay, enum ITimeControlledGovernance.OperationType oType, address implementation, bool trusted_) external
```

Returns the manager version required by a trusted implementation

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| delay | uint256 |  |
| oType | enum ITimeControlledGovernance.OperationType |  |
| implementation | address | The address of the implementation |
| trusted_ | bool |  |

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

