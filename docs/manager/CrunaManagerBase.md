# Solidity API

## CrunaManagerBase

Base contract for managers and services

### _IMPLEMENTATION_SLOT

```solidity
bytes32 _IMPLEMENTATION_SLOT
```

Storage slot with the address of the current implementation.
This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
validated in the constructor.

### upgrade

```solidity
function upgrade(address implementation_) external virtual
```

Upgrade the implementation of the manager

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation_ | address | The new implementation |

### migrate

```solidity
function migrate(uint256 previousVersion) external virtual
```

Execute actions needed in a new manager based on the previous version

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| previousVersion | uint256 | The previous version |

### _combineBytes4

```solidity
function _combineBytes4(bytes4 a, bytes4 b) internal pure returns (bytes8)
```

Utility function to combine two bytes4 into a bytes8

### _isProtected

```solidity
function _isProtected() internal view returns (bool)
```

Check if the NFT is protected
Required by SignatureValidator

### _isProtector

```solidity
function _isProtector(address protector_) internal view returns (bool)
```

Checks if an address is a protector
Required by SignatureValidator

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protector_ | address | The address to check |

### _version

```solidity
function _version() internal pure virtual returns (uint256)
```

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

