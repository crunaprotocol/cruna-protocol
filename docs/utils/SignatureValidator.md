# Solidity API

## SignatureValidator

_This contract is used to validate signatures.
It is based on EIP712 and supports typed messages V4._

### _MAX_VALID_FOR

```solidity
uint256 _MAX_VALID_FOR
```

_The maximum validFor. If more than this it will conflict with the timestamp._

### _TIMESTAMP_MULTIPLIER

```solidity
uint256 _TIMESTAMP_MULTIPLIER
```

_The multiplier for the timestamp in the timeValidation parameter._

### constructor

```solidity
constructor() internal
```

_EIP712 constructor_

### preApprovals

```solidity
function preApprovals(bytes32 hash) external view returns (address)
```

_See {ISignatureValidator.sol-preApprovals}_

### hashSignature

```solidity
function hashSignature(bytes signature) external pure returns (bytes32)
```

_see {ISignatureValidator.sol-hashSignature}_

### isSignatureUsed

```solidity
function isSignatureUsed(bytes32 hash) external view returns (bool)
```

_see {ISignatureValidator.sol-isSignatureUsed}_

### recoverSigner

```solidity
function recoverSigner(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation, bytes signature) public view returns (address, bytes32)
```

_see {ISignatureValidator-recoverSigner}_

### preApprove

```solidity
function preApprove(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation) external
```

_see {ISignatureValidator-preApprove}_

### _canPreApprove

```solidity
function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual returns (bool)
```

_Checks if someone can pre approve an operation.
Must be implemented by the contract using this base contract_

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

_Validates the timeValidation parameter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| timeValidation | uint256 | The timeValidation parameter |

### _isProtected

```solidity
function _isProtected() internal view virtual returns (bool)
```

_Checks if the NFT is protected.
Must be implemented by the contract using this base contract_

### _isProtector

```solidity
function _isProtector(address protector) internal view virtual returns (bool)
```

_Checks if an address is a protector.
Must be implemented by the contract using this base contract_

### _validateAndCheckSignature

```solidity
function _validateAndCheckSignature(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation, bytes signature) internal virtual
```

_Validates and checks the signature._

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

_Hashes the data._

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

_Util to hash the bytes of the signature saving gas in comparison with using keccak256._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signature | bytes | The signature. |

