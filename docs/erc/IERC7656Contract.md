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

