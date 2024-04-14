# Solidity API

## IInheritanceCrunaPlugin

Interface for the inheritance plugin

### InheritanceConf

Struct to store the configuration for the inheritance

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
struct InheritanceConf {
  address beneficiary;
  uint8 quorum;
  uint8 gracePeriodInWeeks;
  uint8 proofOfLifeDurationInWeeks;
  uint32 lastProofOfLife;
  uint32 extendedProofOfLife;
}
```

### Votes

Struct to store the votes

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
struct Votes {
  address[] nominations;
  mapping(address => address) favorites;
}
```

### SentinelUpdated

```solidity
event SentinelUpdated(address owner, address sentinel, bool status)
```

Emitted when a sentinel is updated

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The owner address |
| sentinel | address | The sentinel address |
| status | bool | True if the sentinel is active, false if it is not |

### InheritanceConfigured

```solidity
event InheritanceConfigured(address owner, uint256 quorum, uint256 proofOfLifeDurationInWeeks, uint256 gracePeriodInWeeks, address beneficiary)
```

Emitted when the inheritance is configured

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The owner address |
| quorum | uint256 | The number of sentinels required to approve a request |
| proofOfLifeDurationInWeeks | uint256 | The duration of the Proof-of-Live, i.e., the number of days after which the sentinels can start the process to inherit the token if the owner does not prove to be alive |
| gracePeriodInWeeks | uint256 | The grace period in weeks |
| beneficiary | address | The beneficiary address |

### ProofOfLife

```solidity
event ProofOfLife(address owner)
```

Emitted when a Proof-of-Life is triggered

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The owner address |

### VotedForBeneficiary

```solidity
event VotedForBeneficiary(address sentinel, address beneficiary)
```

Emitted when a sentinel votes for a beneficiary

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sentinel | address | The sentinel address |
| beneficiary | address | The beneficiary address. If the address == address(0), the vote is to retire the beneficiary |

### BeneficiaryApproved

```solidity
event BeneficiaryApproved(address beneficiary)
```

Emitted when a beneficiary is approved

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beneficiary | address | The beneficiary address |

### QuorumCannotBeZero

```solidity
error QuorumCannotBeZero()
```

Error returned when the quorum is set to 0

### QuorumCannotBeGreaterThanSentinels

```solidity
error QuorumCannotBeGreaterThanSentinels()
```

Error returned when the quorum is greater than the number of sentinels

### InheritanceNotConfigured

```solidity
error InheritanceNotConfigured()
```

Error returned when the inheritance is not set

### StillAlive

```solidity
error StillAlive()
```

Error returned when the owner is still alive, i.e., there is a Proof-of-Life event
more recent than the Proof-of-Life duration

### NotASentinel

```solidity
error NotASentinel()
```

Error returned when the sender is not a sentinel

### NotTheBeneficiary

```solidity
error NotTheBeneficiary()
```

Error returned when the sender is not the beneficiary

### BeneficiaryNotSet

```solidity
error BeneficiaryNotSet()
```

Error returned when the beneficiary is not set

### WaitingForBeneficiary

```solidity
error WaitingForBeneficiary()
```

Error returned when trying to vote for a beneficiary, while
the grace period for the current beneficiary is not over

### InvalidValidity

```solidity
error InvalidValidity()
```

Error returned when passing a signature with a validFor > MAX_VALID_FOR

### NoVoteToRetire

```solidity
error NoVoteToRetire()
```

Error returned when trying to retire a not-found vote

### InvalidParameters

```solidity
error InvalidParameters()
```

Error returned when the parameters are invalid

### PluginRequiresUpdatedManager

```solidity
error PluginRequiresUpdatedManager(uint256 requiredVersion)
```

Error returned when the plugin is upgraded if requires an updated manager

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| requiredVersion | uint256 | The version required by the plugin |

### setSentinel

```solidity
function setSentinel(address sentinel, bool status, uint256 timestamp, uint256 validFor, bytes signature) external
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
function setSentinels(address[] sentinels, bytes emptySignature) external
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
function configureInheritance(uint8 quorum, uint8 proofOfLifeDurationInWeeks, uint8 gracePeriodInWeeks, address beneficiary, uint256 timestamp, uint256 validFor, bytes signature) external
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

### getSentinelsAndInheritanceData

```solidity
function getSentinelsAndInheritanceData() external view returns (address[], struct IInheritanceCrunaPlugin.InheritanceConf)
```

Return all the sentinels and the inheritance data

### getVotes

```solidity
function getVotes() external view returns (address[])
```

Return all the votes

### countSentinels

```solidity
function countSentinels() external view returns (uint256)
```

Return the number of sentinels

### proofOfLife

```solidity
function proofOfLife() external
```

allows the user to trigger a Proof-of-Live

### voteForBeneficiary

```solidity
function voteForBeneficiary(address beneficiary) external
```

Allows the sentinels to nominate a beneficiary

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beneficiary | address | The beneficiary address If the beneficiary is address(0), the vote is to retire a previously voted beneficiary |

### inherit

```solidity
function inherit() external
```

Allows the beneficiary to inherit the token

### upgrade

```solidity
function upgrade(address implementation_) external
```

Upgrades the implementation of the plugin

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation_ | address | The new implementation |

