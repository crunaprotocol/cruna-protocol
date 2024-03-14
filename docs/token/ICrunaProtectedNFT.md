# Solidity API

## ICrunaProtectedNFT

### NftConf

_Optimized configuration structure for the generic NFT
Elements:
- progressiveTokenIds is used to allow the upgrade of the default manager implementation. It is used to assure that the manager can be upgraded in a safe way.
- allowUntrustedTransfers is used by the managers to allow untrusted plugins to transfer the tokens. Typically, we would set it true for testnets and false for mainnets.
- nextTokenId is the next tokenId to be used. It is used to mint new tokens if progressiveTokenIds is true. Notice the limit to a uint112.
- maxTokenId is the maximum tokenId that can be minted. It is used to limit the minting of new tokens. Notice the limit to a uint112.
- managerHistoryLength is the length of the manager history._

```solidity
struct NftConf {
  bool progressiveTokenIds;
  bool allowUntrustedTransfers;
  uint112 nextTokenId;
  uint112 maxTokenId;
  uint8 managerHistoryLength;
  uint8 unusedField;
}
```

### ManagerHistory

_Manager history structure
Elements:
- firstTokenId is the first tokenId using a specific manager.
- lastTokenId is the last tokenId managed by the same manager.
- managerAddress is the address of the manager._

```solidity
struct ManagerHistory {
  uint112 firstTokenId;
  uint112 lastTokenId;
  address managerAddress;
}
```

### DefaultManagerUpgrade

```solidity
event DefaultManagerUpgrade(address newManagerProxy)
```

_Emitted when the default manager is upgraded_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newManagerProxy | address | The address of the new manager proxy |

### MaxTokenIdChange

```solidity
event MaxTokenIdChange(uint112 maxTokenId)
```

_Emitted when the maxTokenId is changed_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| maxTokenId | uint112 | The new maxTokenId |

### NotTransferable

```solidity
error NotTransferable()
```

_Error returned when the caller is not the token owner_

### NotTheManager

```solidity
error NotTheManager()
```

_Error returned when the caller is not the manager_

### ZeroAddress

```solidity
error ZeroAddress()
```

_Error returned when the caller is not the token owner_

### AlreadyInitiated

```solidity
error AlreadyInitiated()
```

_Error returned when the token is already initiated_

### NotTheTokenOwner

```solidity
error NotTheTokenOwner()
```

_Error returned when the caller is not the token owner_

### CannotUpgradeToAnOlderVersion

```solidity
error CannotUpgradeToAnOlderVersion()
```

_Error returned when trying to upgrade to an older version_

### UntrustedImplementation

```solidity
error UntrustedImplementation(address implementation)
```

_Error returned when the new implementation of the manager is not trusted_

### NotAvailableIfTokenIdsAreNotProgressive

```solidity
error NotAvailableIfTokenIdsAreNotProgressive()
```

_Error returned when trying to call a function that requires progressive token ids_

### InvalidTokenId

```solidity
error InvalidTokenId()
```

_Error returned when the token id is invalid_

### NftNotInitiated

```solidity
error NftNotInitiated()
```

_Error returned when the NFT is not initiated_

### InvalidMaxTokenId

```solidity
error InvalidMaxTokenId()
```

_Error returned when trying too set an invalid MaxTokenId_

### InvalidIndex

```solidity
error InvalidIndex()
```

_Error returned when an index is invalid_

### nftConf

```solidity
function nftConf() external view returns (struct ICrunaProtectedNFT.NftConf)
```

_Returns the configuration of the NFT_

### managerHistory

```solidity
function managerHistory(uint256 index) external view returns (struct ICrunaProtectedNFT.ManagerHistory)
```

_Returns the manager history for a specific index_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | The index |

### setMaxTokenId

```solidity
function setMaxTokenId(uint112 maxTokenId_) external
```

_set the maximum tokenId that can be minted_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| maxTokenId_ | uint112 | The new maxTokenId |

### allowUntrustedTransfers

```solidity
function allowUntrustedTransfers() external view returns (bool)
```

_Returns true if the token allows untrusted plugins to transfer the tokens
This is usually set to true for testnets and false for mainnets_

### init

```solidity
function init(address managerAddress_, bool progressiveTokenIds_, bool allowUntrustedTransfers_, uint112 nextTokenId_, uint112 maxTokenId_) external
```

_Initialize the NFT_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| managerAddress_ | address | The address of the manager |
| progressiveTokenIds_ | bool | If true, the tokenIds will be progressive |
| allowUntrustedTransfers_ | bool | If true, the token will allow untrusted plugins to transfer the tokens |
| nextTokenId_ | uint112 | The next tokenId to be used |
| maxTokenId_ | uint112 | The maximum tokenId that can be minted (it can be 0 if no upper limit) |

### defaultManagerImplementation

```solidity
function defaultManagerImplementation(uint256 _tokenId) external view returns (address)
```

_Returns the address of the default implementation of the manager for a tokenId_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The tokenId |

### upgradeDefaultManager

```solidity
function upgradeDefaultManager(address payable newManagerProxy) external
```

_Upgrade the default manager for any following tokenId_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newManagerProxy | address payable | The address of the new manager proxy |

### managerOf

```solidity
function managerOf(uint256 tokenId) external view returns (address)
```

_Return the address of the manager of a tokenId_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The id of the token. |

### deployPlugin

```solidity
function deployPlugin(address pluginImplementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external returns (address)
```

_Deploys a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pluginImplementation | address | The address of the plugin implementation |
| salt | bytes32 | The salt |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | Specifies the registry to use True if the tokenId must be deployed via ERC6551Registry, false, it must be deployed via CrunaRegistry |

### isDeployed

```solidity
function isDeployed(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external view returns (bool)
```

_Returns if a plugin is deployed_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation | address | The address of the plugin implementation |
| salt | bytes32 | The salt |
| tokenId | uint256 | The tokenId |
| isERC6551Account | bool | Specifies the registry to use True if the tokenId was deployed via ERC6551Registry, false, it was deployed via CrunaRegistry |

