# Solidity API

## CrunaProtectedNFTTimeControlled

This contract is a base for NFTs with protected transfers.
It implements best practices for governance and timelock.

### NotAuthorized

```solidity
error NotAuthorized()
```

Error returned when the caller is not authorized

### constructor

```solidity
constructor(string name_, string symbol_, uint256 minDelay, address[] proposers, address[] executors, address admin) internal
```

construct the contract with a given name, symbol, minDelay, proposers, executors, and admin.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name_ | string | The name of the token. |
| symbol_ | string | The symbol of the token. |
| minDelay | uint256 | The minimum delay for the time lock. |
| proposers | address[] | The initial proposers. |
| executors | address[] | The initial executors. |
| admin | address | The admin of the contract (they should later renounce to the role). |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

### _canManage

```solidity
function _canManage(bool isInitializing) internal view virtual
```

see {CrunaProtectedNFT-_canManage}

