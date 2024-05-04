# Solidity API

## IManagedNFT

Interface for a managed NFT

### ManagedTransfer

```solidity
event ManagedTransfer(bytes32 key, uint256 tokenId)
```

Emitted when a token is transferred by a plugin

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| key | bytes32 | The key of the plugin managing the transfer |
| tokenId | uint256 | The id of the token. |

### managedTransfer

```solidity
function managedTransfer(bytes32 key, uint256 tokenId, address to) external payable
```

Allow a plugin to transfer the token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| key | bytes32 | The key of the plugin managing the transfer |
| tokenId | uint256 | The id of the token. |
| to | address | The address of the recipient. |

