# Solidity API

## InheritanceCrunaPlugin

This contract manages inheritance

### _inheritanceConf

```solidity
struct IInheritanceCrunaPlugin.InheritanceConf _inheritanceConf
```

The object storing the inheritance configuration

### _votes

```solidity
struct IInheritanceCrunaPlugin.Votes _votes
```

The object storing the votes

### requiresToManageTransfer

```solidity
function requiresToManageTransfer() external pure returns (bool)
```

see {IInheritanceCrunaPlugin.sol-requiresToManageTransfer}

### isERC6551Account

```solidity
function isERC6551Account() external pure virtual returns (bool)
```

see {IInheritanceCrunaPlugin.sol-isERC6551Account}

### setSentinel

```solidity
function setSentinel(address sentinel, bool status, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

_see {IInheritanceCrunaPlugin.sol-setSentinel}_

### setSentinels

```solidity
function setSentinels(address[] sentinels, bytes emptySignature) external virtual
```

_see {IInheritanceCrunaPlugin.sol-setSentinels}_

### configureInheritance

```solidity
function configureInheritance(uint8 quorum, uint8 proofOfLifeDurationInWeeks, uint8 gracePeriodInWeeks, address beneficiary, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

_see {IInheritanceCrunaPlugin.sol-configureInheritance}_

### countSentinels

```solidity
function countSentinels() external view virtual returns (uint256)
```

_see {IInheritanceCrunaPlugin.sol-countSentinels}_

### getSentinelsAndInheritanceData

```solidity
function getSentinelsAndInheritanceData() external view virtual returns (address[], struct IInheritanceCrunaPlugin.InheritanceConf)
```

_see {IInheritanceCrunaPlugin.sol-getSentinelsAndInheritanceData}_

### getVotes

```solidity
function getVotes() external view virtual returns (address[])
```

_see {IInheritanceCrunaPlugin.sol-getVotes}_

### proofOfLife

```solidity
function proofOfLife() external virtual
```

_see {IInheritanceCrunaPlugin.sol-proofOfLife}_

### voteForBeneficiary

```solidity
function voteForBeneficiary(address beneficiary) external virtual
```

_see {IInheritanceCrunaPlugin.sol-voteForBeneficiary}_

### inherit

```solidity
function inherit() external virtual
```

_see {IInheritanceCrunaPlugin.sol-inherit}_

### reset

```solidity
function reset() external
```

_see {ICrunaPlugin.sol-reset}_

### requiresResetOnTransfer

```solidity
function requiresResetOnTransfer() external pure returns (bool)
```

_see {ICrunaPlugin.sol-requiresResetOnTransfer}_

### _nameId

```solidity
function _nameId() internal pure virtual returns (bytes4)
```

_see {CrunaPluginBase.sol-_nameId}_

### _setSentinel

```solidity
function _setSentinel(address sentinel, bool status, uint256 timestamp, uint256 validFor, bytes signature) internal virtual
```

_It sets a sentinel_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sentinel | address | The sentinel address |
| status | bool | True if the sentinel is active, false if it is not |
| timestamp | uint256 | The timestamp |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature |

### _configureInheritance

```solidity
function _configureInheritance(uint8 quorum, uint8 proofOfLifeDurationInWeeks, uint8 gracePeriodInWeeks, address beneficiary) internal virtual
```

### _quorumReached

```solidity
function _quorumReached() internal view virtual returns (address)
```

### _isNominated

```solidity
function _isNominated(address beneficiary) internal view virtual returns (bool)
```

### _popNominated

```solidity
function _popNominated(address beneficiary) internal virtual
```

### _resetNominationsAndVotes

```solidity
function _resetNominationsAndVotes() internal virtual
```

### _isASentinel

```solidity
function _isASentinel() internal view virtual returns (bool)
```

### _checkIfStillAlive

```solidity
function _checkIfStillAlive() internal view virtual
```

### _isGracePeriodExpiredForBeneficiary

```solidity
function _isGracePeriodExpiredForBeneficiary() internal virtual returns (bool)
```

### _reset

```solidity
function _reset() internal
```

