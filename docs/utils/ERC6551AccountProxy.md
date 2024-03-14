# Solidity API

## ERC6551AccountProxy

### DEFAULT_IMPLEMENTATION

```solidity
address DEFAULT_IMPLEMENTATION
```

_The default implementation of the contract_

### InvalidImplementation

```solidity
error InvalidImplementation()
```

_Error returned when the implementation is invalid_

### receive

```solidity
receive() external payable virtual
```

_The function that allows to receive ether and generic calls_

### constructor

```solidity
constructor(address _defaultImplementation) public
```

_Constructor_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _defaultImplementation | address | The default implementation of the contract |

### _implementation

```solidity
function _implementation() internal view virtual returns (address)
```

_Returns the implementation of the contract_

### _fallback

```solidity
function _fallback() internal virtual
```

_Fallback function that redirect all the calls not in this proxy to the implementation_

