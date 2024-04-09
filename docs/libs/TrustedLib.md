# Solidity API

## TrustedLib

### areUntrustedImplementationsAllowed

```solidity
function areUntrustedImplementationsAllowed() internal view returns (bool)
```

Returns if untrusted implementations are allowed

_When on those chain, it is possible to skip the requirement that an implementation is trusted.

To keep this function efficient, we support only the most popular chains at the moment.

- Goerli
- BNB Testnet
- Chronos Testnet
- Fantom
- Avalance Fuji
- Celo Alfajores
- Gnosis Testnet
- Polygon Mumbai
- Arbitrum Testnet
- Sepolia
- Base Sepolia_
