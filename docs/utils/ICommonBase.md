# Solidity API

## ICommonBase

### NotTheTokenOwner

```solidity
error NotTheTokenOwner()
```

Error returned when the caller is not the token owner

### vault

```solidity
function vault() external view returns (contract CrunaProtectedNFT)
```

Returns the vault, i.e., the CrunaProtectedNFT contract

