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

Set a convenient variable to refer to the contract itself

### _nftConf

```solidity
struct ICrunaProtectedNFT.NftConf _nftConf
```

The configuration of the NFT

### _managerHistory

```solidity
struct ICrunaProtectedNFT.ManagerHistory[] _managerHistory
```

The manager history

### _approvedTransfers

```solidity
mapping(uint256 => uint256) _approvedTransfers
```

internal variable used to make protected NFT temporarily transferable.
It is set before the transfer and removed after it, during the manager transfer process.

### onlyManagerOf

```solidity
modifier onlyManagerOf(uint256 tokenId)
```

allows only the manager of a certain tokenId to call the function.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The id of the token. |

### nftConf

```solidity
function nftConf() external view virtual returns (struct ICrunaProtectedNFT.NftConf)
```

Returns the configuration of the NFT

### managerHistory

```solidity
function managerHistory(uint256 index) external view virtual returns (struct ICrunaProtectedNFT.ManagerHistory)
```

Returns the manager history for a specific index

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | The index |

### version

```solidity
function version() external pure virtual returns (uint256)
```

Returns the version of the contract.
The format is similar to semver, where any element takes 3 digits.
For example, version 1.2.14 is 1_002_014.

### constructor

```solidity
constructor(string name_, string symbol_) internal payable
```

### init

```solidity
function init(address managerAddress_, bool progressiveTokenIds_, uint96 nextTokenId_, uint96 maxTokenId_) external virtual
```

Initialize the NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| managerAddress_ | address | The address of the manager |
| progressiveTokenIds_ | bool | If true, the tokenIds will be progressive |
| nextTokenId_ | uint96 | The next tokenId to be used. If progressiveTokenIds_ == true and the project must reserve some tokens to special addresses, community, etc. You set the nextTokenId_ to the first not reserved token. Be careful, your function minting by tokenId MUST check that the tokenId is not higher than nextTokenId. If not, when trying to mint tokens by amount, as soon as nextTokenId reaches the minted tokenId, the function will revert, blocking any future minting. If you code may risk so, set a function that allow you to correct the nextTokenId to skip the token minted by mistake. |
| maxTokenId_ | uint96 | The maximum tokenId that can be minted (it can be 0 if no upper limit) |

### setMaxTokenId

```solidity
function setMaxTokenId(uint96 maxTokenId_) external virtual
```

set the maximum tokenId that can be minted

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| maxTokenId_ | uint96 | The new maxTokenId |

### defaultManagerImplementation

```solidity
function defaultManagerImplementation(uint256 _tokenId) external view virtual returns (address)
```

Returns the address of the default implementation of the manager for a tokenId

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The tokenId |

### upgradeDefaultManager

```solidity
function upgradeDefaultManager(address payable newManagerProxy) external virtual
```

Upgrade the default manager for any following tokenId

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newManagerProxy | address payable | The address of the new manager proxy |

### managedTransfer

```solidity
function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external payable virtual
```

see {ICrunaProtectedNFT-managedTransfer}.

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_see {ERC165-supportsInterface}._

### isTransferable

```solidity
function isTransferable(uint256 tokenId, address from, address to) external view virtual returns (bool)
```

Used to check whether the given token is transferable or not.
If this function returns `false`, the transfer of the token MUST revert execution.
If the tokenId does not exist, this method MUST revert execution, unless the token is being checked for
 minting.
The `from` parameter MAY be used to also validate the approval of the token for transfer, but anyone
 interacting with this function SHOULD NOT rely on it as it is not mandated by the proposal.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | ID of the token being checked |
| from | address | Address from which the token is being transferred |
| to | address | Address to which the token is being transferred |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Boolean value indicating whether the given token is transferable |

### defaultLocked

```solidity
function defaultLocked() external pure virtual returns (bool)
```

Returns the current default lock status for tokens.
The returned value MUST reflect the status indicated by the most recent `DefaultLocked` event.

### locked

```solidity
function locked(uint256 tokenId) external view virtual returns (bool)
```

Returns the lock status of a specific token.
If no `Locked` event has been emitted for the token, it MUST return the current default lock status.
The function MUST revert if the token does not exist.

### emitLockedEvent

```solidity
function emitLockedEvent(uint256 tokenId, bool locked_) external payable
```

Emit a Locked event when a protector is set and the token becomes locked.
This function is not virtual because should not be overridden to avoid issues when
called by the manager (when protectors are set/unset)
Making it payable reduces the gas cost.

### plug

```solidity
function plug(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account, bytes data) external payable virtual
```

Deploys an unmanaged service

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the service implementation |
| salt | bytes32 | The salt |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | Specifies the registry to use True if the tokenId must be deployed via ERC6551Registry, false, it must be deployed via ERC7656Registry |
| data | bytes |  |

### isDeployed

```solidity
function isDeployed(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external view virtual returns (bool)
```

Returns if a plugin is deployed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the plugin implementation |
| salt | bytes32 | The salt |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | Specifies the registry to use True if the tokenId was deployed via ERC6551Registry, false, it was deployed via ERC7656Registry |

### managerOf

```solidity
function managerOf(uint256 tokenId) external view virtual returns (address)
```

Return the address of the manager of a tokenId

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The id of the token. |

### _managerOf

```solidity
function _managerOf(uint256 tokenId) internal view virtual returns (address)
```

internal function to return the manager (for lesser gas consumption)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | the id of the token |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | the address of the manager |

### addressOfDeployed

```solidity
function addressOfDeployed(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external view virtual returns (address)
```

Returns the address of a deployed manager or plugin

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the manager or plugin implementation |
| salt | bytes32 | The salt |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | Specifies the registry to use True if the tokenId was deployed via ERC6551Registry, false, it was deployed via ERC7656Registry |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the deployed manager or plugin |

### _defaultManagerImplementation

```solidity
function _defaultManagerImplementation(uint256 _tokenId) internal view virtual returns (address)
```

Returns the default implementation of the manager for a specific tokenId

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | the tokenId |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the implementation |

### _canManage

```solidity
function _canManage(bool isInitializing) internal view virtual
```

Specify if the caller can call some function.
Must be overridden to specify who can manage changes during initialization and later

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| isInitializing | bool | If true, the function is being called during initialization, if false, it is supposed to the called later. A time controlled NFT can allow the admin to call some functions during the initialization, requiring later a standard proposal/execition process. |

### _update

```solidity
function _update(address to, uint256 tokenId, address auth) internal virtual returns (address)
```

see {ERC721-_update}.

### _isTransferable

```solidity
function _isTransferable(uint256 tokenId, address from, address to) internal view virtual returns (bool)
```

Function to define a token as transferable or not, according to IERC6454

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

Mints tokens by amount.

_It works only if nftConf.progressiveTokenIds is true._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of the recipient. |
| amount | uint256 | The amount of tokens to mint. |

### _mintAndActivate

```solidity
function _mintAndActivate(address to, uint256 tokenId) internal virtual
```

This function will mint a new token and initialize it.

_Use it carefully if nftConf.progressiveTokenIds is true. Usually, you may
want to do so if you reserved some specific token to the project itself, the DAO, etc.
An example:
You reserve 1000 tokens to the DAO, `nextTokenId` will be 1001.
If you have a function the uses directly _mintAndActivate you MUST set a check
to avoid minting tokens with higher id than `nextTokenId`. If than happens, when
you call again _mintAndActivateByAmount, if one of the supposed tokens is already minted,
the function will revert and the error may be unfixable._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of the recipient. |
| tokenId | uint256 | The id of the token. |

