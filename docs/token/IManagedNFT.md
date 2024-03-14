# Solidity API

## IManagedNFT

_Interface for a managed NFT_

### ManagedTransfer

```solidity
event ManagedTransfer(bytes4 pluginNameId, uint256 tokenId)
```

_Emitted when a token is transferred by a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pluginNameId | bytes4 | The hash of the plugin name. |
| tokenId | uint256 | The id of the token. |

### managedTransfer

```solidity
function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external
```

_Allow a plugin to transfer the token_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pluginNameId | bytes4 | The hash of the plugin name. |
| tokenId | uint256 | The id of the token. |
| to | address | The address of the recipient. |

