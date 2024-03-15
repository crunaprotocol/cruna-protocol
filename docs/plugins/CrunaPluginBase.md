# Solidity API

## CrunaPluginBase

Base contract for plugins

### _conf

```solidity
struct ICrunaPlugin.Conf _conf
```

The internal configuration of the plugin

### ifMustNotBeReset

```solidity
modifier ifMustNotBeReset()
```

Verifies that the plugin must not be reset

### init

```solidity
function init() external
```

_see {ICrunaPlugin-init}_

### manager

```solidity
function manager() external view virtual returns (contract CrunaManager)
```

_see {ICrunaPlugin-manager}_

### version

```solidity
function version() external pure virtual returns (uint256)
```

_see {IVersioned-version}_

### upgrade

```solidity
function upgrade(address implementation_) external virtual
```

_see {ICrunaPlugin-upgrade}_

### resetOnTransfer

```solidity
function resetOnTransfer() external
```

_see {ICrunaPlugin-resetOnTransfer}_

### _canPreApprove

```solidity
function _canPreApprove(bytes4, address, address signer) internal view virtual returns (bool)
```

Internal function to verify if a signer can pre approve an operation (if the sender is a protector)
The params:
- operation The selector of the called function
- the actor to be approved
- signer The signer of the operation (the protector)

### _version

```solidity
function _version() internal pure virtual returns (uint256)
```

_see {IVersioned-version}_

### _isProtected

```solidity
function _isProtected() internal view virtual returns (bool)
```

internal function to check if the NFT is currently protected

### _isProtector

```solidity
function _isProtector(address protector) internal view virtual returns (bool)
```

Internal function to check if an address is a protector

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protector | address | The address to check |

