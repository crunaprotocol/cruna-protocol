# Solidity API

## ManagerConstants

_Constants for the manager. Using functions instead of state variables makes easier to manage future upgrades._

### maxActors

```solidity
function maxActors() internal pure returns (uint256)
```

_The maximum number of actors that can be added to the manager_

### protectorId

```solidity
function protectorId() internal pure returns (bytes4)
```

_Equivalent to bytes4(keccak256("PROTECTOR"))_

### safeRecipientId

```solidity
function safeRecipientId() internal pure returns (bytes4)
```

_Equivalent to bytes4(keccak256("SAFE_RECIPIENT"))_

### gasToEmitLockedEvent

```solidity
function gasToEmitLockedEvent() internal pure returns (uint256)
```

_The gas passed to the Protected NFT when asking to emit a Locked event_

### gasToResetPlugin

```solidity
function gasToResetPlugin() internal pure returns (uint256)
```

_The gas passed to plugins when asking to them mark the plugin as must-be-reset_

