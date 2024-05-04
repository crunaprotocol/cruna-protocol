# Solidity API

## ERC7656Contract

Abstract contract to link a contract to an NFT

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool)
```

_Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
to learn more about how these ids are created.

This function call must use less than 30 000 gas._

### token

```solidity
function token() public view virtual returns (uint256, address, uint256)
```

Returns the token linked to the contract

### owner

```solidity
function owner() public view virtual returns (address)
```

Returns the owner of the token

### salt

```solidity
function salt() public view virtual returns (bytes32)
```

Returns the salt used when creating the contract

### _salt

```solidity
function _salt() internal view returns (bytes32)
```

### tokenAddress

```solidity
function tokenAddress() public view virtual returns (address)
```

Returns the address of the token contract

### _tokenAddress

```solidity
function _tokenAddress() internal view returns (address)
```

### tokenId

```solidity
function tokenId() public view virtual returns (uint256)
```

Returns the tokenId of the token

### _tokenId

```solidity
function _tokenId() internal view returns (uint256)
```

### implementation

```solidity
function implementation() public view virtual returns (address)
```

Returns the implementation used when creating the contract

### _implementation

```solidity
function _implementation() internal view returns (address)
```

