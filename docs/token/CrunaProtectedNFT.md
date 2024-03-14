# Solidity API

## IVersionedManager

A convenient interface to mix nameId, version and default implementations

### DEFAULT_IMPLEMENTATION

```solidity
function DEFAULT_IMPLEMENTATION() external pure returns (address)
```

### version

```solidity
function version() external pure returns (uint256)
```

### nameId

```solidity
function nameId() external pure returns (bytes4)
```

## CrunaProtectedNFT

This contracts is a base for NFTs with protected transfers. It must be extended implementing
the _canManage function to define who can alter the contract. Two versions are provided in this repo,CrunaProtectedNFTTimeControlled.sol and CrunaProtectedNFTOwnable.sol. The first is the recommended one, since it allows a governance aligned with best practices. The second is simpler, and can be used in less critical scenarios. If none of them fits your needs, you can implement your own policy.

### _SELF

```solidity
address _SELF
```

_Set a convenient variable to refer to the contract itself_

### _approvedTransfers

```solidity
mapping(uint256 => bool) _approvedTransfers
```

_internal variable used to make protected NFT temporarily transferable.
It is set before the transfer and removed after it, during the manager transfer process._

### onlyManagerOf

```solidity
modifier onlyManagerOf(uint256 tokenId)
```

_allows only the manager of a certain tokenId to call the function._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The id of the token. |

### nftConf

```solidity
function nftConf() external view virtual returns (struct ICrunaProtectedNFT.NftConf)
```

_see {ICrunaProtectedNFT.sol-nftConf}_

### managerHistory

```solidity
function managerHistory(uint256 index) external view virtual returns (struct ICrunaProtectedNFT.ManagerHistory)
```

_see {ICrunaProtectedNFT.sol-managerHistory}_

### version

```solidity
function version() external pure virtual returns (uint256)
```

_see {IVersioned.sol-version}_

### constructor

```solidity
constructor(string name_, string symbol_) internal
```

### init

```solidity
function init(address managerAddress_, bool progressiveTokenIds_, bool allowUntrustedTransfers_, uint112 nextTokenId_, uint112 maxTokenId_) external virtual
```

_see {ICrunaProtectedNFT.sol-init}_

### allowUntrustedTransfers

```solidity
function allowUntrustedTransfers() external view virtual returns (bool)
```

_see {ICrunaProtectedNFT.sol-allowUntrustedTransfers}_

### setMaxTokenId

```solidity
function setMaxTokenId(uint112 maxTokenId_) external virtual
```

_see {ICrunaProtectedNFT.sol-setMaxTokenId}_

### defaultManagerImplementation

```solidity
function defaultManagerImplementation(uint256 _tokenId) external view virtual returns (address)
```

_see {ICrunaProtectedNFT.sol-defaultManagerImplementation}_

### upgradeDefaultManager

```solidity
function upgradeDefaultManager(address payable newManagerProxy) external virtual
```

_see {ICrunaProtectedNFT.sol-upgradeDefaultManager}_

### managedTransfer

```solidity
function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external virtual
```

_see {ICrunaProtectedNFT.sol-managedTransfer}._

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

### isTransferable

```solidity
function isTransferable(uint256 tokenId, address from, address to) external view virtual returns (bool)
```

_see {IERC6454.sol-isTransferable}_

### defaultLocked

```solidity
function defaultLocked() external pure virtual returns (bool)
```

_see {IERC6982.sol-defaultLocked}_

### locked

```solidity
function locked(uint256 tokenId) external view virtual returns (bool)
```

_see {IERC6982.sol-Locked}_

### emitLockedEvent

```solidity
function emitLockedEvent(uint256 tokenId, bool locked_) external
```

_Emit a Locked event when a protector is set and the token becomes locked.
This function is not virtual because should not be overridden to avoid issues when
called by the manager (when protectors are set/unset)_

### deployPlugin

```solidity
function deployPlugin(address pluginImplementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external virtual returns (address)
```

_see {ICrunaProtectedNFT.sol-deployPlugin}_

### isDeployed

```solidity
function isDeployed(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external view virtual returns (bool)
```

_see {ICrunaProtectedNFT.sol-isDeployed}_

### managerOf

```solidity
function managerOf(uint256 tokenId) external view virtual returns (address)
```

_see {ICrunaProtectedNFT.sol-managerOf}_

### _managerOf

```solidity
function _managerOf(uint256 tokenId) internal view virtual returns (address)
```

_internal function to return the manager (for lesser gas consumption)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | the id of the token |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | the address of the manager |

### _defaultManagerImplementation

```solidity
function _defaultManagerImplementation(uint256 _tokenId) internal view virtual returns (address)
```

_Returns the default implementation of the manager for a specific tokenId_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | the tokenId |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the implementation |

### _addressOfDeployed

```solidity
function _addressOfDeployed(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) internal view virtual returns (address)
```

_Internal function to return the address of a deployed token bound contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the implementation |
| salt | bytes32 | The salt |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | If true, the tokenId has been deployed via ERC6551Registry, if false, via CrunaRegistry |

### _canManage

```solidity
function _canManage(bool isInitializing) internal view virtual
```

_Specify if the caller can call some function.
Must be overridden to specify who can manage changes during initialization and later_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| isInitializing | bool | If true, the function is being called during initialization, if false, it is supposed to the called later. A time controlled NFT can allow the admin to call some functions during the initialization, requiring later a standard proposal/execition process. |

### _update

```solidity
function _update(address to, uint256 tokenId, address auth) internal virtual returns (address)
```

_See {ERC721-_update}._

### _isTransferable

```solidity
function _isTransferable(uint256 tokenId, address from, address to) internal view virtual returns (bool)
```

_Function to define a token as transferable or not, according to IERC6454_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The id of the token. |
| from | address | The address of the sender. |
| to | address | The address of the recipient. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | true if the token is transferable, false otherwise. |

### _mintAndActivateByAmount

```solidity
function _mintAndActivateByAmount(address to, uint256 amount) internal virtual
```

_Mints tokens by amount.
It works only if nftConf.progressiveTokenIds is true._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of the recipient. |
| amount | uint256 | The amount of tokens to mint. |

### _mintAndActivate

```solidity
function _mintAndActivate(address to, uint256 tokenId) internal virtual
```

_This function will mint a new token and initialize it.
Use it carefully if nftConf.progressiveTokenIds is true. Usually, used to
reserve some specific token to the project itself, the DAO, etc._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of the recipient. |
| tokenId | uint256 | The id of the token. |

### _deploy

```solidity
function _deploy(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) internal virtual returns (address)
```

_This function deploys a token-bound contract (manager or plugin)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the implementation |
| salt | bytes32 | The salt |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | If true, the tokenId will be deployed via ERC6551Registry, if false, via CrunaRegistry |

