# Solidity API

## ERC7656Registry

### create

```solidity
function create(address implementation, bytes32 salt, uint256, address tokenContract, uint256 tokenId) external returns (address)
```

### compute

```solidity
function compute(address implementation, bytes32 salt, uint256, address, uint256) external view returns (address)
```

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external pure returns (bool)
```

_Returns true if interfaceId is IERC7656Registry's interfaceId
This contract does not explicitly extend IERC165 to keep the bytecode as small as possible_

