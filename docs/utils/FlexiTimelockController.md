# Solidity API

## FlexiTimelockController

Extension of the TimelockController that allows for upgrade proposers and executors if needed.

### MustCallThroughTimeController

```solidity
error MustCallThroughTimeController()
```

Error returned when the function is not called through the TimelockController

### ProposerAlreadyExists

```solidity
error ProposerAlreadyExists()
```

Error returned when trying to add an already existing proposer

### ProposerDoesNotExist

```solidity
error ProposerDoesNotExist()
```

Error returned when trying to remove a non-existing proposer

### ExecutorAlreadyExists

```solidity
error ExecutorAlreadyExists()
```

Error returned when trying to add an already existing executor

### ExecutorDoesNotExist

```solidity
error ExecutorDoesNotExist()
```

Error returned when trying to remove a non-existing executor

### onlyThroughTimeController

```solidity
modifier onlyThroughTimeController()
```

Modifier to allow only the TimelockController to call a function.

### constructor

```solidity
constructor(uint256 minDelay, address[] proposers, address[] executors, address admin) public
```

Initializes the contract with a given minDelay and initial proposers and executors.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minDelay | uint256 | The minimum delay for the time lock. |
| proposers | address[] | The initial proposers. |
| executors | address[] | The initial executors. |
| admin | address | The admin of the contract (they should later renounce to the role). |

### addProposer

```solidity
function addProposer(address proposer) external
```

Adds a new proposer.
Can only be called through the TimelockController.

### removeProposer

```solidity
function removeProposer(address proposer) external
```

Removes a proposer.
Can only be called through the TimelockController.

### addExecutor

```solidity
function addExecutor(address executor) external
```

Adds a new executor.
Can only be called through the TimelockController.

### removeExecutor

```solidity
function removeExecutor(address executor) external
```

Removes an executor.
Can only be called through the TimelockController.

