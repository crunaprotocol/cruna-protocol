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

see {IInheritanceCrunaPlugin-requiresToManageTransfer}

### isERC6551Account

```solidity
function isERC6551Account() external pure virtual returns (bool)
```

see {IInheritanceCrunaPlugin-isERC6551Account}

### setSentinel

```solidity
function setSentinel(address sentinel, bool status, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

see {IInheritanceCrunaPlugin-setSentinel}

### setSentinels

```solidity
function setSentinels(address[] sentinels, bytes emptySignature) external virtual
```

see {IInheritanceCrunaPlugin-setSentinels}

### configureInheritance

```solidity
function configureInheritance(uint8 quorum, uint8 proofOfLifeDurationInWeeks, uint8 gracePeriodInWeeks, address beneficiary, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

see {IInheritanceCrunaPlugin-configureInheritance}

### countSentinels

```solidity
function countSentinels() external view virtual returns (uint256)
```

see {IInheritanceCrunaPlugin-countSentinels}

### getSentinelsAndInheritanceData

```solidity
function getSentinelsAndInheritanceData() external view virtual returns (address[], struct IInheritanceCrunaPlugin.InheritanceConf)
```

see {IInheritanceCrunaPlugin-getSentinelsAndInheritanceData}

### getVotes

```solidity
function getVotes() external view virtual returns (address[])
```

see {IInheritanceCrunaPlugin-getVotes}

### proofOfLife

```solidity
function proofOfLife() external virtual
```

see {IInheritanceCrunaPlugin-proofOfLife}

### voteForBeneficiary

```solidity
function voteForBeneficiary(address beneficiary) external virtual
```

see {IInheritanceCrunaPlugin-voteForBeneficiary}

### inherit

```solidity
function inherit() external virtual
```

see {IInheritanceCrunaPlugin-inherit}

### reset

```solidity
function reset() external
```

see {ICrunaPlugin-reset}

### requiresResetOnTransfer

```solidity
function requiresResetOnTransfer() external pure returns (bool)
```

see {ICrunaPlugin-requiresResetOnTransfer}

### _nameId

```solidity
function _nameId() internal pure virtual returns (bytes4)
```

see {CrunaPluginBase-_nameId}

### _setSentinel

```solidity
function _setSentinel(address sentinel, bool status, uint256 timestamp, uint256 validFor, bytes signature) internal virtual
```

It sets a sentinel

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

