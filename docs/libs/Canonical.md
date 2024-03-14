# Solidity API

## Canonical

_Returns the address where registries and guardian have been deployed
There are two set of addresses. In both, the registry are on the same addresses, but
the guardian has a different address for testing and deployment to localhost (using the 2nd
and 3rd hardhat standard wallets as proposer and executor).
This contract is for development and testing purposes only. When the package is published
to Npm, the addresses will be replaced by the actual addresses of the deployed contracts._

### crunaRegistry

```solidity
function crunaRegistry() internal pure returns (contract ICrunaRegistry)
```

_Returns the CrunaRegistry contract_

### erc6551Registry

```solidity
function erc6551Registry() internal pure returns (contract IERC6551Registry)
```

_Returns the ERC6551Registry contract_

### crunaGuardian

```solidity
function crunaGuardian() internal pure returns (contract ICrunaGuardian)
```

_Returns the CrunaGuardian contract_

