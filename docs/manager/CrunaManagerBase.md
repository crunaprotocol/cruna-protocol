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

### pluginKey

```solidity
function pluginKey(bytes4 nameId_, address impl_, bytes4 salt_) external view virtual returns (bytes32)
```

### _pluginKey

```solidity
function _pluginKey(bytes4 nameId_, address impl_, bytes4 salt_) internal view virtual returns (bytes32)
```

### _implFromKey

```solidity
function _implFromKey(bytes32 key_) internal pure returns (address)
```

### _nameIdFromKey

```solidity
function _nameIdFromKey(bytes32 key_) internal pure returns (bytes4)
```

### _saltFromKey

```solidity
function _saltFromKey(bytes32 key_) internal pure returns (bytes4)
```

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

