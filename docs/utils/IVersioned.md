# Solidity API

## IVersioned

### version

```solidity
function version() external view returns (uint256)
```

Returns the version of the contract.
The format is similar to semver, where any element takes 3 digits.
For example, version 1.2.14 is 1_002_014.

