# Solidity API

## ITokenLinkedContract

### token

```solidity
function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId)
```

_Returns the token linked to the contract_

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

_Returns the owner of the token_

### tokenAddress

```solidity
function tokenAddress() external view returns (address)
```

_Returns the address of the token contract_

### tokenId

```solidity
function tokenId() external view returns (uint256)
```

_Returns the tokenId of the token_

### implementation

```solidity
function implementation() external view returns (address)
```

_Returns the implementation used when creating the contract_

