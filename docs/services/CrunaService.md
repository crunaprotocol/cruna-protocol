# Solidity API

## CrunaService

Base contract for services

### _onBeforeInit

```solidity
function _onBeforeInit(bytes data) internal virtual
```

### init

```solidity
function init(bytes data) external virtual
```

_see {ICrunaManagedService.sol-init}_

### version

```solidity
function version() external pure virtual returns (uint256)
```

Returns the version of the contract.
The format is similar to semver, where any element takes 3 digits.
For example, version 1.2.14 is 1_002_014.

### isERC6551Account

```solidity
function isERC6551Account() external pure virtual returns (bool)
```

_see {ICrunaManagedService.sol-isERC6551Account}_

### _version

```solidity
function _version() internal pure virtual returns (uint256)
```

Returns the version of the contract.
The format is similar to semver, where any element takes 3 digits.
For example, version 1.2.14 is 1_002_014.

### isManaged

```solidity
function isManaged() external pure returns (bool)
```

Called when deploying the service to check if it must be managed

