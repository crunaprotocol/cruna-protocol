# Solidity API

## SignatureValidator

This contract is used to validate signatures.
It is based on EIP712 and supports typed messages V4.

### _MAX_VALID_FOR

```solidity
uint256 _MAX_VALID_FOR
```

The maximum validFor. If more than this it will conflict with the timestamp.

### _TIMESTAMP_MULTIPLIER

```solidity
uint256 _TIMESTAMP_MULTIPLIER
```

The multiplier for the timestamp in the timeValidation parameter.

### constructor

```solidity
constructor() internal payable
```

EIP712 constructor

### preApprovals

```solidity
function preApprovals(bytes32 hash) external view returns (address)
```

_Returns the address who approved a pre-approved operation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| hash | bytes32 | The hash of the operation. |

### hashSignature

```solidity
function hashSignature(bytes signature) external pure returns (bytes32)
```

_Returns the hash of a signature._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signature | bytes | The signature. |

### isSignatureUsed

```solidity
function isSignatureUsed(bytes32 hash) external view returns (bool)
```

_Returns if a signature has been used._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| hash | bytes32 | The hash of the signature. |

### recoverSigner

```solidity
function recoverSigner(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation, bytes signature) public view returns (address, bytes32)
```

_This function validates a signature trying to be as flexible as possible.
As long as called inside the same contract, the cost adding some more parameters is negligible.
Instead, calling it from other contracts can be expensive._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| selector | bytes4 | The selector of the function being called. |
| owner | address | The owner of the token. |
| actor | address | The actor being authorized. It can be address(0) if the parameter is not needed. |
| tokenAddress | address | The address of the token. |
| tokenId | uint256 | The id of the token. |
| extra | uint256 | The extra |
| extra2 | uint256 | The extra2 |
| extra3 | uint256 | The extra3 |
| timeValidation | uint256 | A combination of timestamp and validity of the signature. |
| signature | bytes |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The signer of the signature and the hash of the signature. |
| [1] | bytes32 |  |

### preApprove

```solidity
function preApprove(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation) external
```

_Pre-approve a signature._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| selector | bytes4 | The selector of the function being called. |
| owner | address | The owner of the token. |
| actor | address | The actor being authorized. It can be address(0) if the parameter is not needed. |
| tokenAddress | address | The address of the token. |
| tokenId | uint256 | The id of the token. |
| extra | uint256 | The extra |
| extra2 | uint256 | The extra2 |
| extra3 | uint256 | The extra3 |
| timeValidation | uint256 | A combination of timestamp and validity of the signature. |

### _canPreApprove

```solidity
function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual returns (bool)
```

Checks if someone can pre approve an operation.
Must be implemented by the contract using this base contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| selector | bytes4 | The selector of the function being called. |
| actor | address | The actor being authorized. |
| signer | address | The signer of the operation (the protector) |

### _isProtected

```solidity
function _isProtected() internal view virtual returns (bool)
```

Checks if the NFT is protected.
Must be implemented by the contract using this base contract

### _isProtector

```solidity
function _isProtector(address protector) internal view virtual returns (bool)
```

Checks if an address is a protector.
Must be implemented by the contract using this base contract

### _validateAndCheckSignature

```solidity
function _validateAndCheckSignature(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation, bytes signature) internal virtual
```

Validates and checks the signature.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| selector | bytes4 | The selector of the function being called. |
| owner | address | The owner of the token. |
| actor | address | The actor being authorized. |
| tokenAddress | address | The address of the token. |
| tokenId | uint256 | The id of the token. |
| extra | uint256 | The extra |
| extra2 | uint256 | The extra2 |
| extra3 | uint256 | The extra3 |
| timeValidation | uint256 | A combination of timestamp and validity of the signature. |
| signature | bytes | The signature. |

### _hashData

```solidity
function _hashData(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation) internal pure returns (bytes32)
```

Hashes the data.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| selector | bytes4 | The selector of the function being called. |
| owner | address | The owner of the token. |
| actor | address | The actor being authorized. |
| tokenAddress | address | The address of the token. |
| tokenId | uint256 | The id of the token. |
| extra | uint256 | The extra |
| extra2 | uint256 | The extra2 |
| extra3 | uint256 | The extra3 |
| timeValidation | uint256 | A combination of timestamp and validity of the signature. |

### _hashBytes

```solidity
function _hashBytes(bytes signature) internal pure returns (bytes32 hash)
```

Util to hash the bytes of the signature saving gas in comparison with using keccak256.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signature | bytes | The signature. |

