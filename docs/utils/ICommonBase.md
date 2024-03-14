# Solidity API

## ICommonBase

### NotTheTokenOwner

```solidity
error NotTheTokenOwner()
```

_Error returned when the caller is not the token owner_

### vault

```solidity
function vault() external view returns (contract CrunaProtectedNFT)
```

_Returns the vault, i.e., the CrunaProtectedNFT contract_

