# Solidity API

## Canonical

Returns the address where registries and guardian have been deployed

_There are two set of addresses. In both, the registry are on the same addresses, but
the guardian has a different address for testing and deployment to localhost (using the 2nd
and 3rd hardhat standard wallets as proposer and executor).
This contract is for development and testing purposes only. When the package is published
to Npm, the addresses will be replaced by the actual addresses of the deployed contracts._

### erc7656Registry

```solidity
function erc7656Registry() internal pure returns (contract IERC7656Registry)
```

Returns the ERC7656Registry contract

### erc6551Registry

```solidity
function erc6551Registry() internal pure returns (contract IERC6551Registry)
```

Returns the ERC6551Registry contract

### crunaGuardian

```solidity
function crunaGuardian() internal pure returns (contract ICrunaGuardian)
```

Returns the CrunaGuardian contract

