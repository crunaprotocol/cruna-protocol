# Solidity API

## TimeControlledGovernance

An optimized time controlled proposers/executors contract

### constructor

```solidity
constructor(uint256 minDelay, address firstProposer, address firstExecutor, address admin) public
```

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minDelay | uint256 | The minimum delay for time lock operations |
| firstProposer | address | The address that can propose time lock operations |
| firstExecutor | address | The address that can execute time lock operations |
| admin | address | The address that can admin the contract. It should renounce to the role, as soon as possible. |

### getAuthorized

```solidity
function getAuthorized() public view returns (struct ITimeControlledGovernance.Authorized[])
```

Get the list of all authorized addresses

### getMinDelay

```solidity
function getMinDelay() public view returns (uint256)
```

Get the min delay

### getAdmin

```solidity
function getAdmin() public view returns (address)
```

Get the admin

### isAuthorized

```solidity
function isAuthorized(address sender, enum ITimeControlledGovernance.Role role_) public view returns (bool)
```

Check if an address is authorized

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The address to check |
| role_ | enum ITimeControlledGovernance.Role | The role to check |

### countAuthorized

```solidity
function countAuthorized() public view returns (uint256, uint256)
```

Count the number of proposers and executors

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

### renounceAdmin

```solidity
function renounceAdmin() external
```

Renounce the admin role

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

### getOperation

```solidity
function getOperation(bytes32 operation) public view returns (uint256)
```

Get info about an operation

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operation | bytes32 | The operation |

### _canExecute

```solidity
function _canExecute(uint256 delay, enum ITimeControlledGovernance.OperationType oType, bytes32 operation) internal returns (bool)
```

