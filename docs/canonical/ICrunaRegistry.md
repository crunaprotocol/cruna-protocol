# Solidity API

## ICrunaRegistry

_Manages the creation of token bound accounts_

### TokenLinkedContractCreated

```solidity
event TokenLinkedContractCreated(address contractAddress, address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
```

_The registry MUST emit the ERC6551AccountCreated event upon successful account creation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The address of the created account |
| implementation | address | The address of the implementation contract |
| salt | bytes32 | The salt to use for the create2 operation |
| chainId | uint256 | The chain id of the chain where the account is being created |
| tokenContract | address | The address of the token contract |
| tokenId | uint256 | The id of the token |

### createTokenLinkedContract

```solidity
function createTokenLinkedContract(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external returns (address account)
```

_Creates a token bound account for a non-fungible token.
If account has already been created, returns the account address without calling create2._

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
| account | address | The address of the token bound account |

### tokenLinkedContract

```solidity
function tokenLinkedContract(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external view returns (address account)
```

_Returns the computed token bound account address for a non-fungible token._

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
| account | address | The address of the token bound account |

