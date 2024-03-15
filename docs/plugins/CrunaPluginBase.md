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

Initialize the plugin. It must be implemented, but can do nothing is no init is needed.

### manager

```solidity
function manager() external view virtual returns (contract CrunaManager)
```

Returns the manager

### version

```solidity
function version() external pure virtual returns (uint256)
```

Returns the version of the contract.
The format is similar to semver, where any element takes 3 digits.
For example, version 1.2.14 is 1_002_014.

### upgrade

```solidity
function upgrade(address implementation_) external virtual
```

Upgrade the implementation of the manager/plugin
Notice that the owner can upgrade active or disable plugins
so that, if a plugin is compromised, the user can disable it,
wait for a new trusted implementation and upgrade it.

### resetOnTransfer

```solidity
function resetOnTransfer() external
```

Reset the plugin to the factory settings

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

Returns the version of the contract.
The format is similar to semver, where any element takes 3 digits.
For example, version 1.2.14 is 1_002_014.

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

