# Solidity API

## InheritanceCrunaPlugin

This contract manages inheritance

### _IMPLEMENTATION_SLOT

```solidity
bytes32 _IMPLEMENTATION_SLOT
```

Storage slot with the address of the current implementation.
This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
validated in the constructor.

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

_see {ICrunaManagedService.sol-requiresToManageTransfer}_

### setSentinel

```solidity
function setSentinel(address sentinel, bool status, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

Set a sentinel for the token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sentinel | address | The sentinel address |
| status | bool | True to activate, false to deactivate |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the tokensOwner |

### setSentinels

```solidity
function setSentinels(address[] sentinels, bytes emptySignature) external virtual
```

Set a list of sentinels for the token
It is a convenience function to set multiple sentinels at once, but it
works only if no protectors have been set up. Useful for initial settings.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sentinels | address[] | The sentinel addresses |
| emptySignature | bytes | The signature of the tokensOwner |

### configureInheritance

```solidity
function configureInheritance(uint8 quorum, uint8 proofOfLifeDurationInWeeks, uint8 gracePeriodInWeeks, address beneficiary, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

Configures an inheritance
Some parameters are optional depending on the scenario.
There are three scenarios:

- The user sets a beneficiary. The beneficiary can inherit the NFT as soon as a Proof-of-Life is missed.
- The user sets more than a single sentinel. The sentinels propose a beneficiary, and when the quorum is reached, the beneficiary can inherit the NFT.
- The user sets a beneficiary and some sentinels. In this case, the beneficiary has a grace period to inherit the NFT. If after that grace period the beneficiary has not inherited the NFT, the sentinels can propose a new beneficiary.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| quorum | uint8 | The number of sentinels required to approve a request |
| proofOfLifeDurationInWeeks | uint8 | The duration of the Proof-of-Live, i.e., the number of days after which the sentinels can start the process to inherit the token if the owner does not prove to be alive |
| gracePeriodInWeeks | uint8 | The grace period in weeks |
| beneficiary | address | The beneficiary address |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the tokensOwner |

### countSentinels

```solidity
function countSentinels() external view virtual returns (uint256)
```

Return the number of sentinels

### getSentinelsAndInheritanceData

```solidity
function getSentinelsAndInheritanceData() external view virtual returns (address[], struct IInheritanceCrunaPlugin.InheritanceConf)
```

Return all the sentinels and the inheritance data

### getVotes

```solidity
function getVotes() external view virtual returns (address[])
```

Return all the votes

### proofOfLife

```solidity
function proofOfLife() external virtual
```

allows the user to trigger a Proof-of-Live

### voteForBeneficiary

```solidity
function voteForBeneficiary(address beneficiary) external virtual
```

Allows the sentinels to nominate a beneficiary

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beneficiary | address | The beneficiary address If the beneficiary is address(0), the vote is to retire a previously voted beneficiary |

### inherit

```solidity
function inherit() external virtual
```

Allows the beneficiary to inherit the token

### resetService

```solidity
function resetService() external payable
```

_see {ICrunaManagedService.sol-reset}_

### requiresResetOnTransfer

```solidity
function requiresResetOnTransfer() external pure returns (bool)
```

### upgrade

```solidity
function upgrade(address implementation_) external virtual
```

Upgrades the implementation of the plugin

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation_ | address | The new implementation |

### _version

```solidity
function _version() internal pure virtual returns (uint256)
```

Returns the version of the contract.
The format is similar to semver, where any element takes 3 digits.
For example, version 1.2.14 is 1_002_014.

### _nameId

```solidity
function _nameId() internal pure virtual returns (bytes4)
```

Internal function that must be overridden by the contract to
return the name id of the contract

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

It configures inheritance

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| quorum | uint8 | The quorum |
| proofOfLifeDurationInWeeks | uint8 | The proof of life duration in weeks |
| gracePeriodInWeeks | uint8 | The grace period in weeks |
| beneficiary | address | The beneficiary |

### _quorumReached

```solidity
function _quorumReached() internal view virtual returns (address)
```

Checks if the quorum has been reached

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The beneficiary if the quorum has been reached, address(0) otherwise |

### _isNominated

```solidity
function _isNominated(address beneficiary) internal view virtual returns (bool)
```

Check is a beneficiary has been nominated

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beneficiary | address | The beneficiary to check |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the beneficiary has been nominated, false otherwise |

### _popNominated

```solidity
function _popNominated(address beneficiary) internal virtual
```

Removes a nominated beneficiary

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beneficiary | address | The beneficiary to remove |

### _resetNominationsAndVotes

```solidity
function _resetNominationsAndVotes() internal virtual
```

Resets nominations and votes

### _isASentinel

```solidity
function _isASentinel() internal view virtual returns (bool)
```

Checks if the sender is a sentinel

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the sender is a sentinel, false otherwise |

### _checkIfStillAlive

```solidity
function _checkIfStillAlive() internal view virtual
```

Checks if the owner is still alive

### _isGracePeriodExpiredForBeneficiary

```solidity
function _isGracePeriodExpiredForBeneficiary() internal virtual returns (bool)
```

Checks if the grace period has expired

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the grace period has expired, false otherwise |

### _resetService

```solidity
function _resetService() internal
```

Reset the plugin configuration

