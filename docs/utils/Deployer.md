# Solidity API

## Deployer

This contract manages deploy-related functions

### _erc7656Registry

```solidity
function _erc7656Registry() internal pure returns (contract IERC7656Registry)
```

Returns the ERC7656Registry contract

### _erc6551Registry

```solidity
function _erc6551Registry() internal pure returns (contract IERC6551Registry)
```

Returns the ERC6551Registry contract

### _isDeployed

```solidity
function _isDeployed(address implementation, bytes32 salt, address tokenAddress, uint256 tokenId, bool isERC6551Account) internal view virtual returns (bool)
```

Returns if a plugin is deployed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the implementation |
| salt | bytes32 | The salt |
| tokenAddress | address |  |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | Specifies the registry to use True if the tokenId was deployed via ERC6551Registry, false, it was deployed via ERC7656Registry |

### _addressOf

```solidity
function _addressOf(address implementation, bytes32 salt, address tokenAddress, uint256 tokenId, bool isERC6551Account) internal view virtual returns (address)
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

