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

_see {ICrunaRegistry-createTokenLinkedContract}_

### tokenLinkedContract

```solidity
function tokenLinkedContract(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external view returns (address)
```

_see {ICrunaRegistry-tokenLinkedContract}_

