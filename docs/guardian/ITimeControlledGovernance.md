# Solidity API

## ITimeControlledGovernance

An optimized time controlled proposers/executors contract

### OperationType

The type of operation
- Proposal: a new operation is proposed
- Cancellation: an operation is cancelled
- Execution: an operation is executed

```solidity
enum OperationType {
  Proposal,
  Cancellation,
  Execution
}
```

### Role

The role of the sender
- Proposer: the sender can propose operations
- Executor: the sender can execute operations
- Any: the sender can cancel operations and check if it has a role

```solidity
enum Role {
  Proposer,
  Executor,
  Any
}
```

### Authorized

The structure of an authorized address
- addr: the address
- role: the role of the address

```solidity
struct Authorized {
  address addr;
  enum ITimeControlledGovernance.Role role;
}
```

### OperationProposed

```solidity
event OperationProposed(bytes32 operation, address proposer, uint256 delay)
```

Emitted when an operation is proposed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operation | bytes32 | The hash of the operation |
| proposer | address | The proposer |
| delay | uint256 | The delay before the operation can be executed |

### OperationExecuted

```solidity
event OperationExecuted(bytes32 operation, address executor)
```

Emitted when an operation is executed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operation | bytes32 | The hash of the operation |
| executor | address | The executor |

### OperationCancelled

```solidity
event OperationCancelled(bytes32 operation, address executor)
```

Emitted when an operation is cancelled
Both proposer and executor can cancel an operation

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operation | bytes32 | The hash of the operation |
| executor | address | The executor (it can be a proposer as well) |

### AdminRenounced

```solidity
event AdminRenounced()
```

Emitted when the admin is renounced

### InvalidDelay

```solidity
error InvalidDelay()
```

Error returned when the delay is invalid

### InvalidRequest

```solidity
error InvalidRequest()
```

Error returned when the request is invalid

### TooEarlyToExecute

```solidity
error TooEarlyToExecute()
```

Error returned when it is too early to execute an operation

### AlreadyProposed

```solidity
error AlreadyProposed()
```

Error returned when the operation is already proposed

### InvalidRole

```solidity
error InvalidRole()
```

Error returned when the role is invalid

### Forbidden

```solidity
error Forbidden()
```

Error returned when the request is forbidden

### RoleNeeded

```solidity
error RoleNeeded()
```

Error returned when trying to remove last proposer/executor

### ProposalNotFound

```solidity
error ProposalNotFound()
```

Error returned when the operation is not found

### renounceAdmin

```solidity
function renounceAdmin() external
```

Renounce the admin role

### setMinDelay

```solidity
function setMinDelay(uint256 delay, enum ITimeControlledGovernance.OperationType oType, uint256 minDelay) external
```

Set the min delay

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| delay | uint256 | The delay before the operation can be executed |
| oType | enum ITimeControlledGovernance.OperationType | The type of operation |
| minDelay | uint256 | The new min delay |

### setAuthorized

```solidity
function setAuthorized(uint256 delay, enum ITimeControlledGovernance.OperationType oType, address toBeAuthorized, enum ITimeControlledGovernance.Role role, bool active) external
```

Authorize a new proposer/executor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| delay | uint256 | The delay before the operation can be executed |
| oType | enum ITimeControlledGovernance.OperationType | The type of operation |
| toBeAuthorized | address | The address to be authorized |
| role | enum ITimeControlledGovernance.Role | The role of the address |
| active | bool | If true, the address is active, otherwise if to be removed |

### getMinDelay

```solidity
function getMinDelay() external view returns (uint256)
```

Get the min delay

### getAdmin

```solidity
function getAdmin() external view returns (address)
```

Get the admin

### getAuthorized

```solidity
function getAuthorized() external view returns (struct ITimeControlledGovernance.Authorized[])
```

Get the list of all authorized addresses

### getOperation

```solidity
function getOperation(bytes32 operation) external view returns (uint256)
```

Get info about an operation

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operation | bytes32 | The operation |

### isAuthorized

```solidity
function isAuthorized(address sender, enum ITimeControlledGovernance.Role role_) external view returns (bool)
```

Check if an address is authorized

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The address to check |
| role_ | enum ITimeControlledGovernance.Role | The role to check |

### countAuthorized

```solidity
function countAuthorized() external view returns (uint256, uint256)
```

Count the number of proposers and executors

