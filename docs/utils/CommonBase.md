# Solidity API

## CommonBase

Base contract for managers and services

### onlyTokenOwner

```solidity
modifier onlyTokenOwner()
```

Error returned when the caller is not the token owner

### nameId

```solidity
function nameId() external view returns (bytes4)
```

Returns the name id of the contract

### _nameId

```solidity
function _nameId() internal view virtual returns (bytes4)
```

Internal function that must be overridden by the contract to
return the name id of the contract

### vault

```solidity
function vault() external view virtual returns (contract CrunaProtectedNFT)
```

Returns the vault, i.e., the CrunaProtectedNFT contract

### _vault

```solidity
function _vault() internal view virtual returns (contract CrunaProtectedNFT)
```

Returns the vault, i.e., the CrunaProtectedNFT contract

