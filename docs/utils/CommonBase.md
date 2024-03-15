# Solidity API

## CommonBase

Base contract for managers and plugins

### _IMPLEMENTATION_SLOT

```solidity
bytes32 _IMPLEMENTATION_SLOT
```

Storage slot with the address of the current implementation.
This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
validated in the constructor.

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

### _hashString

```solidity
function _hashString(string input) internal pure returns (bytes32 result)
```

Returns the keccak256 of a string variable.
It saves gas compared to keccak256(abi.encodePacked(string)).

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string to hash |

### _stringToBytes4

```solidity
function _stringToBytes4(string str) internal pure returns (bytes4)
```

Returns the equivalent of bytes4(keccak256(str).

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| str | string | The string to hash |

### _vault

```solidity
function _vault() internal view virtual returns (contract CrunaProtectedNFT)
```

Returns the vault, i.e., the CrunaProtectedNFT contract

