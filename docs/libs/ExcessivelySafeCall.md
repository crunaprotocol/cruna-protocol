# Solidity API

## ExcessivelySafeCall

A library to make calls to untrusted contracts safer

The original code is at https://github.com/nomad-xyz/ExcessivelySafeCall

### BufLengthOverflow

```solidity
error BufLengthOverflow()
```

### excessivelySafeCall

```solidity
function excessivelySafeCall(address _target, uint256 _gas, uint256 _value, uint16 _maxCopy, bytes _calldata) internal returns (bool, bytes)
```

Use when you _really_ really _really_ don't trust the called
contract. This prevents the called contract from causing reversion of
the caller in as many ways as we can.

_The main difference between this and a solidity low-level call is
that we limit the number of bytes that the callee can cause to be
copied to caller memory. This prevents stupid things like malicious
contracts returning 10,000,000 bytes causing a local OOG when copying
to memory._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _target | address | The address to call |
| _gas | uint256 | The amount of gas to forward to the remote contract |
| _value | uint256 | The value in wei to send to the remote contract |
| _maxCopy | uint16 | The maximum number of bytes of returndata to copy to memory. |
| _calldata | bytes | The data to send to the remote contract |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | success and returndata, as `.call()`. Returndata is capped to `_maxCopy` bytes. |
| [1] | bytes |  |

