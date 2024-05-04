# Solidity API

## IERC7656Registry

Manages the creation of token linked accounts

_Modified registry based on ERC6551Registry
https://github.com/erc6551/reference/blob/main/src/ERC6551Registry.sol

The ERC165 interfaceId is 0xc6bdc908_

### Created

```solidity
event Created(address contractAddress, address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
```

The registry MUST emit the Created event upon successful contract creation.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The address of the created contract |
| implementation | address | The address of the implementation contract |
| salt | bytes32 | The salt to use for the create2 operation |
| chainId | uint256 | The chain id of the chain where the contract is being created |
| tokenContract | address | The address of the token contract |
| tokenId | uint256 | The id of the token |

### CreationFailed

```solidity
error CreationFailed()
```

The registry MUST revert with CreationFailed error if the create2 operation fails.

### create

```solidity
function create(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external returns (address account)
```

Creates a token linked account for a non-fungible token.
If account has already been created, returns the account address without calling create2.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the implementation contract |
| salt | bytes32 | The salt to use for the create2 operation |
| chainId | uint256 | The chain id of the chain where the account is being created |
| tokenContract | address | The address of the token contract |
| tokenId | uint256 | The id of the token Emits Created event. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address of the token linked account |

### compute

```solidity
function compute(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external view returns (address account)
```

Returns the computed token linked account address for a non-fungible token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the implementation contract |
| salt | bytes32 | The salt to use for the create2 operation |
| chainId | uint256 | The chain id of the chain where the account is being created |
| tokenContract | address | The address of the token contract |
| tokenId | uint256 | The id of the token |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address of the token linked account |

