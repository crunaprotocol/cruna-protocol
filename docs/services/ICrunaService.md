# Solidity API

## ICrunaService

Interface for services

### Forbidden

```solidity
error Forbidden()
```

Error returned when trying to initialize the service if not authorized

### init

```solidity
function init(bytes data) external
```

Initialize the plugin. It must be implemented, but can do nothing is no init is needed.
We call this function init to avoid conflicts with the `initialize` function used in
upgradeable contracts

### isERC6551Account

```solidity
function isERC6551Account() external pure returns (bool)
```

Called by the manager to know if the plugin is an ERC6551 account
We do not expect that contract check the interfaceId because the service
is not required to extend IERC165, so that can cause issues.

### isManaged

```solidity
function isManaged() external pure returns (bool)
```

Called when deploying the service to check if it must be managed
An unmanaged service should always return false

