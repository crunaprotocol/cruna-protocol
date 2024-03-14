# Solidity API

## FlexiTimelockController

_Extension of the TimelockController that allows for upgrade proposers and executors if needed._

### MustCallThroughTimeController

```solidity
error MustCallThroughTimeController()
```

_Error returned when the function is not called through the TimelockController_

### ProposerAlreadyExists

```solidity
error ProposerAlreadyExists()
```

_Error returned when trying to add an already existing proposer_

### ProposerDoesNotExist

```solidity
error ProposerDoesNotExist()
```

_Error returned when trying to remove a non-existing proposer_

### ExecutorAlreadyExists

```solidity
error ExecutorAlreadyExists()
```

_Error returned when trying to add an already existing executor_

### ExecutorDoesNotExist

```solidity
error ExecutorDoesNotExist()
```

_Error returned when trying to remove a non-existing executor_

### onlyThroughTimeController

```solidity
modifier onlyThroughTimeController()
```

_Modifier to allow only the TimelockController to call a function._

### constructor

```solidity
constructor(uint256 minDelay, address[] proposers, address[] executors, address admin) public
```

_Initializes the contract with a given minDelay and initial proposers and executors._

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

_Adds a new proposer.
Can only be called through the TimelockController._

### removeProposer

```solidity
function removeProposer(address proposer) external
```

_Removes a proposer.
Can only be called through the TimelockController._

### addExecutor

```solidity
function addExecutor(address executor) external
```

_Adds a new executor.
Can only be called through the TimelockController._

### removeExecutor

```solidity
function removeExecutor(address executor) external
```

_Removes an executor.
Can only be called through the TimelockController._

