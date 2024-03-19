# Solidity API

## IERC7656Contract

### token

```solidity
function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId)
```

Returns the token linked to the contract

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chainId of the token |
| tokenContract | address | The address of the token contract |
| tokenId | uint256 | The tokenId of the token |

### owner

```solidity
function owner() external view returns (address)
```

Returns the owner of the token

### tokenAddress

```solidity
function tokenAddress() external view returns (address)
```

Returns the address of the token contract

### tokenId

```solidity
function tokenId() external view returns (uint256)
```

Returns the tokenId of the token

### implementation

```solidity
function implementation() external view returns (address)
```

Returns the implementation used when creating the contract

