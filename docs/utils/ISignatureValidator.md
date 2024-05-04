# Solidity API

## ISignatureValidator

Validates signatures

### PreApproved

```solidity
event PreApproved(bytes32 hash, address signer)
```

Emitted when a signature is pre-approved.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| hash | bytes32 | The hash of the signature. |
| signer | address | The signer of the signature. |

### TimestampInvalidOrExpired

```solidity
error TimestampInvalidOrExpired()
```

_Error returned when a timestamp is invalid or expired._

### NotAuthorized

```solidity
error NotAuthorized()
```

_Error returned when a called in unauthorized._

### NotPermittedWhenProtectorsAreActive

```solidity
error NotPermittedWhenProtectorsAreActive()
```

_Error returned when trying to call a protected operation without a valid signature_

### WrongDataOrNotSignedByProtector

```solidity
error WrongDataOrNotSignedByProtector()
```

_Error returned when the signature is not valid._

### SignatureAlreadyUsed

```solidity
error SignatureAlreadyUsed()
```

_Error returned when the signature is already used._

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
function recoverSigner(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation, bytes signature) external view returns (address, bytes32)
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

