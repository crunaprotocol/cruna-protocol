# Solidity API

## CrunaManagedService

Base contract for services

### _conf

```solidity
struct ICrunaManagedService.Conf _conf
```

The internal configuration of the plugin

### ifMustNotBeReset

```solidity
modifier ifMustNotBeReset()
```

Verifies that the plugin must not be reset

### _onBeforeInit

```solidity
function _onBeforeInit(bytes data) internal virtual
```

### init

```solidity
function init(bytes data) external
```

_see {ICrunaManagedService.sol-init}_

### crunaManager

```solidity
function crunaManager() external view virtual returns (contract CrunaManager)
```

_see {ICrunaManagedService.sol-manager}_

### version

```solidity
function version() external pure virtual returns (uint256)
```

Returns the version of the contract.
The format is similar to semver, where any element takes 3 digits.
For example, version 1.2.14 is 1_002_014.

### resetOnTransfer

```solidity
function resetOnTransfer() external payable
```

_see {ICrunaManagedService.sol-resetOnTransfer}_

### requiresToManageTransfer

```solidity
function requiresToManageTransfer() external pure virtual returns (bool)
```

_see {ICrunaManagedService.sol-requiresToManageTransfer}_

### requiresResetOnTransfer

```solidity
function requiresResetOnTransfer() external pure virtual returns (bool)
```

_see {ICrunaManagedService.sol-requiresResetOnTransfer}_

### requiresManagerVersion

```solidity
function requiresManagerVersion() external pure virtual returns (uint256)
```

_see {ICrunaManagedService.sol-requiresManagerVersion}_

### isERC6551Account

```solidity
function isERC6551Account() external pure virtual returns (bool)
```

_see {ICrunaManagedService.sol-isERC6551Account}_

### isManaged

```solidity
function isManaged() external pure returns (bool)
```

Called when deploying the service to check if it must be managed

### resetService

```solidity
function resetService() external payable virtual
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
function _isProtected() internal view returns (bool)
```

internal function to check if the NFT is currently protected

### _isProtector

```solidity
function _isProtector(address protector) internal view returns (bool)
```

Internal function to check if an address is a protector

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protector | address | The address to check |

