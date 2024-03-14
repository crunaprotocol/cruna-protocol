# Solidity API

## CommonBase

_Base contract for managers and plugins_

### _IMPLEMENTATION_SLOT

```solidity
bytes32 _IMPLEMENTATION_SLOT
```

_Storage slot with the address of the current implementation.
This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
validated in the constructor._

### onlyTokenOwner

```solidity
modifier onlyTokenOwner()
```

_Error returned when the caller is not the token owner_

### nameId

```solidity
function nameId() external view returns (bytes4)
```

_Returns the name id of the contract_

### _nameId

```solidity
function _nameId() internal view virtual returns (bytes4)
```

_Internal function that must be overridden by the contract to
return the name id of the contract_

### vault

```solidity
function vault() external view virtual returns (contract CrunaProtectedNFT)
```

_Returns the vault, i.e., the CrunaProtectedNFT contract_

### _hashString

```solidity
function _hashString(string input) internal pure returns (bytes32 result)
```

_Returns the keccak256 of a string variable.
It saves gas compared to keccak256(abi.encodePacked(string))._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string to hash |

### _stringToBytes4

```solidity
function _stringToBytes4(string str) internal pure returns (bytes4)
```

_Returns the equivalent of bytes4(keccak256(str)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| str | string | The string to hash |

### _vault

```solidity
function _vault() internal view virtual returns (contract CrunaProtectedNFT)
```

_Returns the vault, i.e., the CrunaProtectedNFT contract_

