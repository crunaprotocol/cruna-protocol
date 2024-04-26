# Solidity API

## IManagedNFT

Interface for a managed NFT

### ManagedTransfer

```solidity
event ManagedTransfer(bytes4 pluginNameId, uint256 tokenId)
```

Emitted when a token is transferred by a plugin

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pluginNameId | bytes4 | The hash of the plugin name. |
| tokenId | uint256 | The id of the token. |

### managedTransfer

```solidity
function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external payable
```

Allow a plugin to transfer the token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pluginNameId | bytes4 | The hash of the plugin name. |
| tokenId | uint256 | The id of the token. |
| to | address | The address of the recipient. |

