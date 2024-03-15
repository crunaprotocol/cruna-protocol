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
constructor() internal
```

EIP712 constructor

### preApprovals

```solidity
function preApprovals(bytes32 hash) external view returns (address)
```

see {ISignatureValidator-preApprovals}

### hashSignature

```solidity
function hashSignature(bytes signature) external pure returns (bytes32)
```

see {ISignatureValidator-hashSignature}

### isSignatureUsed

```solidity
function isSignatureUsed(bytes32 hash) external view returns (bool)
```

see {ISignatureValidator-isSignatureUsed}

### recoverSigner

```solidity
function recoverSigner(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation, bytes signature) public view returns (address, bytes32)
```

see {ISignatureValidator-recoverSigner}

### preApprove

```solidity
function preApprove(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation) external
```

see {ISignatureValidator-preApprove}

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

### _validate

```solidity
function _validate(uint256 timeValidation) internal view
```

Validates the timeValidation parameter.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| timeValidation | uint256 | The timeValidation parameter |

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

