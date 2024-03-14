# Solidity API

## TokenLinkedContract

_Abstract contract to link a contract to an NFT_

### token

```solidity
function token() public view virtual returns (uint256, address, uint256)
```

_Returns the token linked to the contract_

### owner

```solidity
function owner() public view virtual returns (address)
```

_Returns the owner of the token_

### tokenAddress

```solidity
function tokenAddress() public view virtual returns (address)
```

_Returns the address of the token contract_

### tokenId

```solidity
function tokenId() public view virtual returns (uint256)
```

_Returns the tokenId of the token_

### implementation

```solidity
function implementation() public view virtual returns (address)
```

_Returns the implementation used when creating the contract_

