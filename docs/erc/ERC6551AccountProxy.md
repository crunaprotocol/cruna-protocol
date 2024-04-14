# Solidity API

## ERC6551AccountProxy

### DEFAULT_IMPLEMENTATION

```solidity
address DEFAULT_IMPLEMENTATION
```

The default implementation of the contract

### InvalidImplementation

```solidity
error InvalidImplementation()
```

Error returned when the implementation is invalid

### receive

```solidity
receive() external payable virtual
```

The function that allows to receive ether and generic calls

### constructor

```solidity
constructor(address _defaultImplementation) public
```

Constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _defaultImplementation | address | The default implementation of the contract |

### _implementation

```solidity
function _implementation() internal view virtual returns (address)
```

Returns the implementation of the contract

### _fallback

```solidity
function _fallback() internal virtual
```

Fallback function that redirect all the calls not in this proxy to the implementation

