# Solidity API

## Deployed

This contract manages deploy-related functions

### _isDeployed

```solidity
function _isDeployed(address implementation, bytes32 salt, address tokenAddress, uint256 tokenId, bool isERC6551Account) internal view virtual returns (bool)
```

Returns if a plugin is deployed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the plugin implementation |
| salt | bytes32 | The salt |
| tokenAddress | address |  |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | Specifies the registry to use True if the tokenId was deployed via ERC6551Registry, false, it was deployed via ERC7656Registry |

### _addressOfDeployed

```solidity
function _addressOfDeployed(address implementation, bytes32 salt, address tokenAddress, uint256 tokenId, bool isERC6551Account) internal view virtual returns (address)
```

Internal function to return the address of a deployed token bound contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the implementation |
| salt | bytes32 | The salt |
| tokenAddress | address |  |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | If true, the tokenId has been deployed via ERC6551Registry, if false, via ERC7656Registry |

### _deploy

```solidity
function _deploy(address implementation, bytes32 salt, address tokenAddress, uint256 tokenId, bool isERC6551Account) internal virtual returns (address)
```

This function deploys a token-linked contract (manager or plugin)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the implementation |
| salt | bytes32 | The salt |
| tokenAddress | address |  |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | If true, the tokenId will be deployed via ERC6551Registry, if false, via ERC7656Registry |

