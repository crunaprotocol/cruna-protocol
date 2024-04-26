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

### isERC6551Account

```solidity
function isERC6551Account() external pure returns (bool)
```

Called by the manager to know if the plugin is an ERC721 account

### isManaged

```solidity
function isManaged() external pure returns (bool)
```

Called when deploying the service to check if it must be managed

