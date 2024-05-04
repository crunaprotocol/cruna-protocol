# Solidity API

## ManagerConstants

Constants for the manager. Using functions instead of state variables makes easier to manage future upgrades.

### maxActors

```solidity
function maxActors() internal pure returns (uint256)
```

The maximum number of actors that can be added to the manager

### protectorId

```solidity
function protectorId() internal pure returns (bytes4)
```

Equivalent to bytes4(keccak256("PROTECTOR"))

### safeRecipientId

```solidity
function safeRecipientId() internal pure returns (bytes4)
```

Equivalent to bytes4(keccak256("SAFE_RECIPIENT"))

### gasToEmitLockedEvent

```solidity
function gasToEmitLockedEvent() internal pure returns (uint256)
```

The gas passed to the Protected NFT when asking to emit a Locked event

### gasToResetPlugin

```solidity
function gasToResetPlugin() internal pure returns (uint256)
```

The gas passed to services when asking to them mark the plugin as must-be-reset

