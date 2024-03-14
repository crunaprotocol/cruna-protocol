# Solidity API

## IInheritanceCrunaPlugin

Interface for the inheritance plugin

### InheritanceConf

_Struct to store the configuration for the inheritance_

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

_Struct to store the votes_

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

_Emitted when a sentinel is updated_

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

_Emitted when the inheritance is configured_

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

_Emitted when a Proof-of-Life is triggered_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The owner address |

### VotedForBeneficiary

```solidity
event VotedForBeneficiary(address sentinel, address beneficiary)
```

_Emitted when a sentinel votes for a beneficiary_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sentinel | address | The sentinel address |
| beneficiary | address | The beneficiary address. If the address == address(0), the vote is to retire the beneficiary |

### BeneficiaryApproved

```solidity
event BeneficiaryApproved(address beneficiary)
```

_Emitted when a beneficiary is approved_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beneficiary | address | The beneficiary address |

### QuorumCannotBeZero

```solidity
error QuorumCannotBeZero()
```

_Error returned when the quorum is set to 0_

### QuorumCannotBeGreaterThanSentinels

```solidity
error QuorumCannotBeGreaterThanSentinels()
```

_Error returned when the quorum is greater than the number of sentinels_

### InheritanceNotConfigured

```solidity
error InheritanceNotConfigured()
```

_Error returned when the inheritance is not set_

### StillAlive

```solidity
error StillAlive()
```

_Error returned when the owner is still alive, i.e., there is a Proof-of-Life event
more recent than the Proof-of-Life duration_

### NotASentinel

```solidity
error NotASentinel()
```

_Error returned when the sender is not a sentinel_

### NotTheBeneficiary

```solidity
error NotTheBeneficiary()
```

_Error returned when the sender is not the beneficiary_

### BeneficiaryNotSet

```solidity
error BeneficiaryNotSet()
```

_Error returned when the beneficiary is not set_

### WaitingForBeneficiary

```solidity
error WaitingForBeneficiary()
```

_Error returned when trying to vote for a beneficiary, while
the grace period for the current beneficiary is not over_

### InvalidValidity

```solidity
error InvalidValidity()
```

_Error returned when passing a signature with a validFor > MAX_VALID_FOR_

### NoVoteToRetire

```solidity
error NoVoteToRetire()
```

_Error returned when trying to retire a not-found vote_

### InvalidParameters

```solidity
error InvalidParameters()
```

_Error returned when the parameters are invalid_

### setSentinel

```solidity
function setSentinel(address sentinel, bool active, uint256 timestamp, uint256 validFor, bytes signature) external
```

_Set a sentinel for the token_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sentinel | address | The sentinel address |
| active | bool | True to activate, false to deactivate |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the tokensOwner |

### setSentinels

```solidity
function setSentinels(address[] sentinels, bytes emptySignature) external
```

_Set a list of sentinels for the token
It is a convenience function to set multiple sentinels at once, but it
works only if no protectors have been set up. Useful for initial settings._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sentinels | address[] | The sentinel addresses |
| emptySignature | bytes | The signature of the tokensOwner |

### configureInheritance

```solidity
function configureInheritance(uint8 quorum, uint8 proofOfLifeDurationInWeeks, uint8 gracePeriodInWeeks, address beneficiary, uint256 timestamp, uint256 validFor, bytes signature) external
```

_Configures an inheritance
Some parameters are optional depending on the scenario.
There are three scenarios:

- The user sets a beneficiary. The beneficiary can inherit the NFT as soon as a Proof-of-Life is missed.
- The user sets more than a single sentinel. The sentinels propose a beneficiary, and when the quorum is reached, the beneficiary can inherit the NFT.
- The user sets a beneficiary and some sentinels. In this case, the beneficiary has a grace period to inherit the NFT. If after that grace period the beneficiary has not inherited the NFT, the sentinels can propose a new beneficiary._

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

_Return all the sentinels and the inheritance data_

### getVotes

```solidity
function getVotes() external view returns (address[])
```

_Return all the votes_

### countSentinels

```solidity
function countSentinels() external view returns (uint256)
```

_Return the number of sentinels_

### proofOfLife

```solidity
function proofOfLife() external
```

_allows the user to trigger a Proof-of-Live_

### voteForBeneficiary

```solidity
function voteForBeneficiary(address beneficiary) external
```

_Allows the sentinels to nominate a beneficiary_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beneficiary | address | The beneficiary address If the beneficiary is address(0), the vote is to retire a previously voted beneficiary |

### inherit

```solidity
function inherit() external
```

_Allows the beneficiary to inherit the token_

