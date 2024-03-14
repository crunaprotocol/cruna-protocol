# Solidity API

## Actor

This contract manages actors (protectors, safe recipients, sentinels, etc.)

### _actors

```solidity
mapping(bytes4 => address[]) _actors
```

The actors for each role

### ZeroAddress

```solidity
error ZeroAddress()
```

Error returned when trying to add a zero address

### ActorAlreadyAdded

```solidity
error ActorAlreadyAdded()
```

Error returned when trying to add an actor already added

### TooManyActors

```solidity
error TooManyActors()
```

Error returned when trying to add too many actors

### ActorNotFound

```solidity
error ActorNotFound()
```

Error returned when an actor is not found

### _getActors

```solidity
function _getActors(bytes4 role) internal view virtual returns (address[])
```

Returns the actors for a role

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| role | bytes4 | The role |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | The actors |

### _actorIndex

```solidity
function _actorIndex(address actor_, bytes4 role) internal view virtual returns (uint256)
```

Returns the index of an actor for a role

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| actor_ | address | The actor |
| role | bytes4 | The role |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The index. If the index == _MAX_ACTORS, the actor is not found |

### _actorCount

```solidity
function _actorCount(bytes4 role) internal view virtual returns (uint256)
```

Returns the number of actors for a role

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| role | bytes4 | The role |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The number of actors |

### _isActiveActor

```solidity
function _isActiveActor(address actor_, bytes4 role) internal view virtual returns (bool)
```

Returns if an actor is active for a role

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| actor_ | address | The actor |
| role | bytes4 | The role |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | If the actor is active |

### _removeActor

```solidity
function _removeActor(address actor_, bytes4 role) internal virtual
```

Removes an actor for a role

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| actor_ | address | The actor |
| role | bytes4 | The role |

### _removeActorByIndex

```solidity
function _removeActorByIndex(uint256 i, bytes4 role) internal virtual
```

Removes an actor for a role by index

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| i | uint256 | The index |
| role | bytes4 | The role |

### _addActor

```solidity
function _addActor(address actor_, bytes4 role_) internal virtual
```

Adds an actor for a role

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| actor_ | address | The actor |
| role_ | bytes4 | The role |

### _deleteActors

```solidity
function _deleteActors(bytes4 role) internal virtual
```

Deletes all the actors for a role

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| role | bytes4 | The role |

