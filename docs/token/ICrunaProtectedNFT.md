# Solidity API

## ICrunaProtectedNFT

### NftConf

Optimized configuration structure for the generic NFT

TokenIds are uint96 for optimization purposes. In particular, having the tokenId as a uint96 allows
to encode the tokenId in the first 12 bytes of the storage slot, leaving the last 20 bytes for the token address
That allows services and other tools to save storage because tokenAddress + tokenId will take a single word.
For example, tokenAddress and tokenId can be encoded as
uint256 tokenAddressAndTokenId = uint256(tokenAddress) << 96 | tokenId;

Elements:
- progressiveTokenIds is used to allow the upgrade of the default manager implementation. It is used to assure that the manager can be upgraded in a safe way.
- nextTokenId is the next tokenId to be used. It is used to mint new tokens if progressiveTokenIds is true.
- maxTokenId is the maximum tokenId that can be minted. It is used to limit the minting of new tokens.
- managerHistoryLength is the length of the manager history.

```solidity
struct NftConf {
  uint96 nextTokenId;
  uint96 maxTokenId;
  bool progressiveTokenIds;
  uint8 managerHistoryLength;
  uint8 unusedField;
}
```

### ManagerHistory

Manager history structure
Elements:
- firstTokenId is the first tokenId using a specific manager.
- lastTokenId is the last tokenId managed by the same manager.
- managerAddress is the address of the manager.

```solidity
struct ManagerHistory {
  uint96 firstTokenId;
  uint96 lastTokenId;
  address managerAddress;
}
```

### DefaultManagerUpgrade

```solidity
event DefaultManagerUpgrade(address newManagerProxy)
```

Emitted when the default manager is upgraded

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newManagerProxy | address | The address of the new manager proxy |

### MaxTokenIdChange

```solidity
event MaxTokenIdChange(uint96 maxTokenId)
```

Emitted when the maxTokenId is changed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| maxTokenId | uint96 | The new maxTokenId |

### NotTransferable

```solidity
error NotTransferable()
```

Error returned when the caller is not the token owner

### NotTheManager

```solidity
error NotTheManager()
```

Error returned when the caller is not the manager

### ZeroAddress

```solidity
error ZeroAddress()
```

Error returned when the caller is not the token owner

### AlreadyInitiated

```solidity
error AlreadyInitiated()
```

Error returned when the token is already initiated

### NotTheTokenOwner

```solidity
error NotTheTokenOwner()
```

Error returned when the caller is not the token owner

### CannotUpgradeToAnOlderVersion

```solidity
error CannotUpgradeToAnOlderVersion()
```

Error returned when trying to upgrade to an older version

### UntrustedImplementation

```solidity
error UntrustedImplementation(address implementation)
```

Error returned when the new implementation of the manager is not trusted

### NotAvailableIfTokenIdsAreNotProgressive

```solidity
error NotAvailableIfTokenIdsAreNotProgressive()
```

Error returned when trying to call a function that requires progressive token ids

### InvalidTokenId

```solidity
error InvalidTokenId()
```

Error returned when the token id is invalid

### NftNotInitiated

```solidity
error NftNotInitiated()
```

Error returned when the NFT is not initiated

### InvalidMaxTokenId

```solidity
error InvalidMaxTokenId()
```

Error returned when trying too set an invalid MaxTokenId

### InvalidIndex

```solidity
error InvalidIndex()
```

Error returned when an index is invalid

### OnlyTokenOwnerOrManager

```solidity
error OnlyTokenOwnerOrManager()
```

Error returned if the sender is neither the manager nor the token owner

### ManagedService

```solidity
error ManagedService()
```

Error returned when the token owner tries to deploy a service that must be managed

### nftConf

```solidity
function nftConf() external view returns (struct ICrunaProtectedNFT.NftConf)
```

Returns the configuration of the NFT

### managerHistory

```solidity
function managerHistory(uint256 index) external view returns (struct ICrunaProtectedNFT.ManagerHistory)
```

Returns the manager history for a specific index

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | The index |

### setMaxTokenId

```solidity
function setMaxTokenId(uint96 maxTokenId_) external
```

set the maximum tokenId that can be minted

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| maxTokenId_ | uint96 | The new maxTokenId |

### init

```solidity
function init(address managerAddress_, bool progressiveTokenIds_, uint96 nextTokenId_, uint96 maxTokenId_) external
```

Initialize the NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| managerAddress_ | address | The address of the manager |
| progressiveTokenIds_ | bool | If true, the tokenIds will be progressive |
| nextTokenId_ | uint96 | The next tokenId to be used. If progressiveTokenIds_ == true and the project must reserve some tokens to special addresses, community, etc. You set the nextTokenId_ to the first not reserved token. Be careful, your function minting by tokenId MUST check that the tokenId is not higher than nextTokenId. If not, when trying to mint tokens by amount, as soon as nextTokenId reaches the minted tokenId, the function will revert, blocking any future minting. If you code may risk so, set a function that allow you to correct the nextTokenId to skip the token minted by mistake. |
| maxTokenId_ | uint96 | The maximum tokenId that can be minted (it can be 0 if no upper limit) |

### defaultManagerImplementation

```solidity
function defaultManagerImplementation(uint256 _tokenId) external view returns (address)
```

Returns the address of the default implementation of the manager for a tokenId

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The tokenId |

### upgradeDefaultManager

```solidity
function upgradeDefaultManager(address payable newManagerProxy) external
```

Upgrade the default manager for any following tokenId

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newManagerProxy | address payable | The address of the new manager proxy |

### managerOf

```solidity
function managerOf(uint256 tokenId) external view returns (address)
```

Return the address of the manager of a tokenId

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The id of the token. |

### addressOfDeployed

```solidity
function addressOfDeployed(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external view returns (address)
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

### plug

```solidity
function plug(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account, bytes data) external payable
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
function isDeployed(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external view returns (bool)
```

Returns if a plugin is deployed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the plugin implementation |
| salt | bytes32 | The salt |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | Specifies the registry to use True if the tokenId was deployed via ERC6551Registry, false, it was deployed via ERC7656Registry |

