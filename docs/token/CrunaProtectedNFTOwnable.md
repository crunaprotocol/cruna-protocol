# Solidity API

## CrunaProtectedNFTOwnable

This contract is a base for NFTs with protected transfers.
We advise to use CrunaProtectedNFTTimeControlled.sol instead, since it allows
a better governance.

### NotTheOwner

```solidity
error NotTheOwner()
```

Error returned when the caller is not the owner

### constructor

```solidity
constructor(string name_, string symbol_, address admin) internal
```

Construct the contract with a given name, symbol, and admin.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name_ | string | The name of the token. |
| symbol_ | string | The symbol of the token. |
| admin | address | The owner of the contract |

### _canManage

```solidity
function _canManage(bool) internal view virtual
```

