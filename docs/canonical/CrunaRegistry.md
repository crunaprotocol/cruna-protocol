# Solidity API

## CrunaRegistry

Manages the creation of token bound accounts

### TokenLinkedContractCreationFailed

```solidity
error TokenLinkedContractCreationFailed()
```

The registry MUST revert with TokenLinkedContractCreationFailed error if the create2 operation fails.

### createTokenLinkedContract

```solidity
function createTokenLinkedContract(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external returns (address)
```

Creates a token bound account for a non-fungible token.
If account has already been created, returns the account address without calling create2.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the implementation contract |
| salt | bytes32 | The salt to use for the create2 operation |
| chainId | uint256 | The chain id of the chain where the account is being created |
| tokenContract | address | The address of the token contract |
| tokenId | uint256 | The id of the token Emits TokenLinkedContractCreated event. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | account The address of the token bound account |

### tokenLinkedContract

```solidity
function tokenLinkedContract(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external view returns (address)
```

Returns the computed token bound account address for a non-fungible token.

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
| [0] | address | account The address of the token bound account |

