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
function createTokenLinkedContract(address implementation, bytes32 salt, uint256, address tokenContract, uint256 tokenId) external returns (address)
```

Deployes token linked contracts.
Look at the interface for more information.

### tokenLinkedContract

```solidity
function tokenLinkedContract(address implementation, bytes32 salt, uint256, address, uint256) external view returns (address)
```

Returns the computed address of a token linked contract
Look at the interface for more information.

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external pure returns (bool)
```

_Returns true if interfaceId is IERC76xxRegistry's interfaceId
This contract does not extend IERC165 to keep the bytecode as small as possible_

