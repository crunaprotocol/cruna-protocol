# Solidity API

## TokenLinkedContract

Abstract contract to link a contract to an NFT

### token

```solidity
function token() public view virtual returns (uint256, address, uint256)
```

Returns the token linked to the contract

### owner

```solidity
function owner() public view virtual returns (address)
```

Returns the owner of the token

### tokenAddress

```solidity
function tokenAddress() public view virtual returns (address)
```

Returns the address of the token contract

### tokenId

```solidity
function tokenId() public view virtual returns (uint256)
```

Returns the tokenId of the token

### implementation

```solidity
function implementation() public view virtual returns (address)
```

Returns the implementation used when creating the contract

