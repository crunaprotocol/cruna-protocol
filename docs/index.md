# Solidity API

## CrunaGuardian

_Manages a registry of trusted implementations and their required manager versions

It is used by
- manager and plugins to upgrade its own  implementation
- manager to trust a new plugin implementation and allow managed transfers_

### InvalidArguments

```solidity
error InvalidArguments()
```

### constructor

```solidity
constructor(uint256 minDelay, address[] proposers, address[] executors, address admin) public
```

_When deployed to production, proposers and executors will be multi-sig wallets owned by the Cruna DAO_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minDelay | uint256 | The minimum delay for timelock operations |
| proposers | address[] | The addresses that can propose timelock operations |
| executors | address[] | The addresses that can execute timelock operations |
| admin | address | The address that can admin the contract. It will renounce to the role, as soon as the  DAO is stable and there are no risks in doing so. |

### version

```solidity
function version() external pure virtual returns (uint256)
```

_see {ICrunaGuardian-setTrustedImplementation}_

### setTrustedImplementation

```solidity
function setTrustedImplementation(bytes4 nameId, address implementation, bool trusted, uint256 requires) external
```

_Sets a given implementation address as trusted, allowing accounts to upgrade to this implementation.
    @param nameId The bytes4 nameId of the implementation
    @param implementation The address of the implementation
    @param trusted When true, it set the implementation as trusted, when false it removes the implementation from the trusted list
    @param requires The version of the manager required by the implementation (for plugins)
      Notice that for managers requires will always be 1_

### trustedImplementation

```solidity
function trustedImplementation(bytes4 nameId, address implementation) external view returns (uint256)
```

_Returns the manager version required by a trusted implementation
    @param nameId The bytes4 nameId of the implementation
    @param implementation The address of the implementation
    @return The version of the manager required by a trusted implementation. If it is 0, it means
      the implementation is not trusted_

## ICrunaGuardian

### TrustedImplementationUpdated

```solidity
event TrustedImplementationUpdated(bytes4 nameId, address implementation, bool trusted, uint256 requires)
```

_Emitted when a trusted implementation is updated
     @param nameId The bytes4 nameId of the implementation
     @param implementation The address of the implementation
     @param trusted Whether the implementation is marked as a trusted or marked as no more trusted
     @param requires The version of the manager required by the implementation_

### setTrustedImplementation

```solidity
function setTrustedImplementation(bytes4 nameId, address implementation, bool trusted, uint256 requires) external
```

_Sets a given implementation address as trusted, allowing accounts to upgrade to this implementation.
    @param nameId The bytes4 nameId of the implementation
    @param implementation The address of the implementation
    @param trusted When true, it set the implementation as trusted, when false it removes the implementation from the trusted list
    @param requires The version of the manager required by the implementation (for plugins)
      Notice that for managers requires will always be 1_

### trustedImplementation

```solidity
function trustedImplementation(bytes4 nameId, address implementation) external view returns (uint256)
```

_Returns the manager version required by a trusted implementation
    @param nameId The bytes4 nameId of the implementation
    @param implementation The address of the implementation
    @return The version of the manager required by a trusted implementation. If it is 0, it means
      the implementation is not trusted_

## FlexiTimelockController

### MustCallThroughTimeController

```solidity
error MustCallThroughTimeController()
```

_Error returned when the function is not called through the TimelockController_

### ProposerAlreadyExists

```solidity
error ProposerAlreadyExists()
```

_Error returned when trying to add an already existing proposer_

### ProposerDoesNotExist

```solidity
error ProposerDoesNotExist()
```

_Error returned when trying to remove a non-existing proposer_

### ExecutorAlreadyExists

```solidity
error ExecutorAlreadyExists()
```

_Error returned when trying to add an already existing executor_

### ExecutorDoesNotExist

```solidity
error ExecutorDoesNotExist()
```

_Error returned when trying to remove a non-existing executor_

### onlyThroughTimeController

```solidity
modifier onlyThroughTimeController()
```

_Modifier to allow only the TimelockController to call a function._

### constructor

```solidity
constructor(uint256 minDelay, address[] proposers, address[] executors, address admin) public
```

_Initializes the contract with a given minDelay and initial proposers and executors.
    @param minDelay The minimum delay for the time lock.
    @param proposers The initial proposers.
    @param executors The initial executors.
    @param admin The admin of the contract (they should later renounce to the role)._

### addProposer

```solidity
function addProposer(address proposer) external
```

_Adds a new proposer.
     Can only be called through the TimelockController._

### removeProposer

```solidity
function removeProposer(address proposer) external
```

_Removes a proposer.
     Can only be called through the TimelockController._

### addExecutor

```solidity
function addExecutor(address executor) external
```

_Adds a new executor.
     Can only be called through the TimelockController._

### removeExecutor

```solidity
function removeExecutor(address executor) external
```

_Removes an executor.
     Can only be called through the TimelockController._

## IVersioned

### version

```solidity
function version() external view returns (uint256)
```

_Returns the version of the contract.
    The format is similar to semver, where any element takes 3 digits.
    For example, version 1.2.14 is 1_002_014._

## CrunaRegistry

### TokenLinkedContractCreationFailed

```solidity
error TokenLinkedContractCreationFailed()
```

_The registry MUST revert with TokenLinkedContractCreationFailed error if the create2 operation fails._

### createTokenLinkedContract

```solidity
function createTokenLinkedContract(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external returns (address)
```

_see {ICrunaRegistry-createTokenLinkedContract}_

### tokenLinkedContract

```solidity
function tokenLinkedContract(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external view returns (address)
```

_see {ICrunaRegistry-tokenLinkedContract}_

## ICrunaRegistry

### TokenLinkedContractCreated

```solidity
event TokenLinkedContractCreated(address contractAddress, address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
```

_The registry MUST emit the ERC6551AccountCreated event upon successful account creation.
    @param contractAddress The address of the created account
    @param implementation The address of the implementation contract
    @param salt The salt to use for the create2 operation
    @param chainId The chain id of the chain where the account is being created
    @param tokenContract The address of the token contract
    @param tokenId The id of the token_

### createTokenLinkedContract

```solidity
function createTokenLinkedContract(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external returns (address account)
```

_Creates a token bound account for a non-fungible token.
    If account has already been created, returns the account address without calling create2.
    @param implementation The address of the implementation contract
    @param salt The salt to use for the create2 operation
    @param chainId The chain id of the chain where the account is being created
    @param tokenContract The address of the token contract
    @param tokenId The id of the token
      Emits TokenLinkedContractCreated event.
    @return account The address of the token bound account_

### tokenLinkedContract

```solidity
function tokenLinkedContract(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external view returns (address account)
```

_Returns the computed token bound account address for a non-fungible token.
    @param implementation The address of the implementation contract
    @param salt The salt to use for the create2 operation
    @param chainId The chain id of the chain where the account is being created
    @param tokenContract The address of the token contract
    @param tokenId The id of the token
    @return account The address of the token bound account_

## IERC6454

### isTransferable

```solidity
function isTransferable(uint256 tokenId, address from, address to) external view returns (bool)
```

## IERC6982

### DefaultLocked

```solidity
event DefaultLocked(bool locked)
```

_MUST be emitted when the contract is deployed to establish the default lock status
          for all tokens. Also, MUST be emitted again if the default lock status changes,
          to ensure the default status for all tokens (without a specific `Locked` event) is updated._

### Locked

```solidity
event Locked(uint256 tokenId, bool locked)
```

_MUST be emitted when the lock status of a specific token changes.
          This status overrides the default lock status for that specific token._

### defaultLocked

```solidity
function defaultLocked() external view returns (bool)
```

_Returns the current default lock status for tokens.
          The returned value MUST reflect the status indicated by the most recent `DefaultLocked` event._

### locked

```solidity
function locked(uint256 tokenId) external view returns (bool)
```

_Returns the lock status of a specific token.
          If no `Locked` event has been emitted for the token, it MUST return the current default lock status.
          The function MUST revert if the token does not exist._

## Canonical

### crunaRegistry

```solidity
function crunaRegistry() internal pure returns (contract ICrunaRegistry)
```

_Returns the CrunaRegistry contract_

### erc6551Registry

```solidity
function erc6551Registry() internal pure returns (contract IERC6551Registry)
```

_Returns the ERC6551Registry contract_

### crunaGuardian

```solidity
function crunaGuardian() internal pure returns (contract ICrunaGuardian)
```

_Returns the CrunaGuardian contract_

## ExcessivelySafeCall

### BufLengthOverflow

```solidity
error BufLengthOverflow()
```

### excessivelySafeCall

```solidity
function excessivelySafeCall(address _target, uint256 _gas, uint256 _value, uint16 _maxCopy, bytes _calldata) internal returns (bool, bytes)
```

Use when you _really_ really _really_ don't trust the called
contract. This prevents the called contract from causing reversion of
the caller in as many ways as we can.

_The main difference between this and a solidity low-level call is
that we limit the number of bytes that the callee can cause to be
copied to caller memory. This prevents stupid things like malicious
contracts returning 10,000,000 bytes causing a local OOG when copying
to memory._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _target | address | The address to call |
| _gas | uint256 | The amount of gas to forward to the remote contract |
| _value | uint256 | The value in wei to send to the remote contract |
| _maxCopy | uint16 | The maximum number of bytes of returndata to copy to memory. |
| _calldata | bytes | The data to send to the remote contract |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | success and returndata, as `.call()`. Returndata is capped to `_maxCopy` bytes. |
| [1] | bytes |  |

## ManagerConstants

### maxActors

```solidity
function maxActors() internal pure returns (uint256)
```

_The maximum number of actors that can be added to the manager_

### protectorId

```solidity
function protectorId() internal pure returns (bytes4)
```

_Equivalent to bytes4(keccak256("PROTECTOR"))_

### safeRecipientId

```solidity
function safeRecipientId() internal pure returns (bytes4)
```

_Equivalent to bytes4(keccak256("SAFE_RECIPIENT"))_

### gasToEmitLockedEvent

```solidity
function gasToEmitLockedEvent() internal pure returns (uint256)
```

_The gas passed to the Protected NFT when asking to emit a Locked event_

### gasToResetPlugin

```solidity
function gasToResetPlugin() internal pure returns (uint256)
```

_The gas passed to plugins when asking to them mark the plugin as must-be-reset_

## Actor

### _actors

```solidity
mapping(bytes4 => address[]) _actors
```

_The actors for each role_

### ZeroAddress

```solidity
error ZeroAddress()
```

_Error returned when trying to add a zero address_

### ActorAlreadyAdded

```solidity
error ActorAlreadyAdded()
```

_Error returned when trying to add an actor already added_

### TooManyActors

```solidity
error TooManyActors()
```

_Error returned when trying to add too many actors_

### ActorNotFound

```solidity
error ActorNotFound()
```

_Error returned when an actor is not found_

### _getActors

```solidity
function _getActors(bytes4 role) internal view virtual returns (address[])
```

_Returns the actors for a role
    @param role The role
    @return The actors_

### _actorIndex

```solidity
function _actorIndex(address actor_, bytes4 role) internal view virtual returns (uint256)
```

_Returns the index of an actor for a role
    @param actor_ The actor
    @param role The role
    @return The index. If the index == _MAX_ACTORS, the actor is not found_

### _actorCount

```solidity
function _actorCount(bytes4 role) internal view virtual returns (uint256)
```

_Returns the number of actors for a role
    @param role The role
    @return The number of actors_

### _isActiveActor

```solidity
function _isActiveActor(address actor_, bytes4 role) internal view virtual returns (bool)
```

_Returns if an actor is active for a role
    @param actor_ The actor
    @param role The role
    @return If the actor is active_

### _removeActor

```solidity
function _removeActor(address actor_, bytes4 role) internal virtual
```

_Removes an actor for a role
    @param actor_ The actor
    @param role The role_

### _removeActorByIndex

```solidity
function _removeActorByIndex(uint256 i, bytes4 role) internal virtual
```

_Removes an actor for a role by index
    @param i The index
    @param role The role_

### _addActor

```solidity
function _addActor(address actor_, bytes4 role_) internal virtual
```

_Adds an actor for a role
    @param actor_ The actor
    @param role_ The role_

### _deleteActors

```solidity
function _deleteActors(bytes4 role) internal virtual
```

_Deletes all the actors for a role
    @param role The role_

## CrunaManager

_The manager of the Cruna NFT
It is the only contract that can manage the NFT. It sets protectors and safe recipients,
plugs and manages plugins, and has the ability to transfer the NFT if there are protectors._

### version

```solidity
function version() external pure virtual returns (uint256)
```

_see {IVersioned.sol-version}_

### pluginByKey

```solidity
function pluginByKey(bytes8 key) external view returns (struct ICrunaManager.PluginConfig)
```

_see {ICrunaManager.sol-getPluginByKey}_

### allPlugins

```solidity
function allPlugins() external view returns (struct ICrunaManager.PluginElement[])
```

_see {ICrunaManager.sol-allPlugins}_

### pluginByIndex

```solidity
function pluginByIndex(uint256 index) external view returns (struct ICrunaManager.PluginElement)
```

_see {ICrunaManager.sol-pluginByIndex}_

### migrate

```solidity
function migrate(uint256) external virtual
```

_see {ICrunaManager.sol-migrate}_

### findProtectorIndex

```solidity
function findProtectorIndex(address protector_) external view virtual returns (uint256)
```

_see {ICrunaManager.sol-findProtectorIndex}_

### isProtector

```solidity
function isProtector(address protector_) external view virtual returns (bool)
```

_see {ICrunaManager.sol-isProtector}_

### hasProtectors

```solidity
function hasProtectors() external view virtual returns (bool)
```

_see {ICrunaManager.sol-hasProtectors}_

### isTransferable

```solidity
function isTransferable(address to) external view returns (bool)
```

_see {ICrunaManager.sol-isTransferable}_

### locked

```solidity
function locked() external view returns (bool)
```

_see {ICrunaManager.sol-locked}_

### countProtectors

```solidity
function countProtectors() external view virtual returns (uint256)
```

_see {ICrunaManager.sol-countProtectors}_

### countSafeRecipients

```solidity
function countSafeRecipients() external view virtual returns (uint256)
```

_see {ICrunaManager.sol-countSafeRecipients}_

### setProtector

```solidity
function setProtector(address protector_, bool status, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

_see {ICrunaManager.sol-setProtector}_

### importProtectorsAndSafeRecipientsFrom

```solidity
function importProtectorsAndSafeRecipientsFrom(uint256 otherTokenId) external virtual
```

_see {ICrunaManager.sol-importProtectorsAndSafeRecipientsFrom}_

### getProtectors

```solidity
function getProtectors() external view virtual returns (address[])
```

_see {ICrunaManager.sol-getProtectors}_

### setSafeRecipient

```solidity
function setSafeRecipient(address recipient, bool status, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

_see {ICrunaManager.sol-setSafeRecipient}_

### isSafeRecipient

```solidity
function isSafeRecipient(address recipient) external view virtual returns (bool)
```

_see {ICrunaManager.sol-isSafeRecipient}_

### getSafeRecipients

```solidity
function getSafeRecipients() external view virtual returns (address[])
```

_see {ICrunaManager.sol-getSafeRecipients}_

### plug

```solidity
function plug(string name, address proxyAddress_, bool canManageTransfer, bool isERC6551Account, bytes4 salt, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

_see {ICrunaManager.sol-plug}_

### changePluginStatus

```solidity
function changePluginStatus(string name, bytes4 salt, enum ICrunaManager.PluginChange change, uint256 timeLock_, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

_see {ICrunaManager.sol-changePluginStatus}_

### trustPlugin

```solidity
function trustPlugin(string name, bytes4 salt) external virtual
```

_see {ICrunaManager.sol-trustPlugin}_

### pluginAddress

```solidity
function pluginAddress(bytes4 nameId_, bytes4 salt) external view virtual returns (address payable)
```

_see {ICrunaManager.sol-countPlugins}_

### plugin

```solidity
function plugin(bytes4 nameId_, bytes4 salt) external view virtual returns (contract CrunaPluginBase)
```

_see {ICrunaManager.sol-plugin}_

### countPlugins

```solidity
function countPlugins() external view virtual returns (uint256, uint256)
```

_see {ICrunaManager.sol-countPlugins}_

### plugged

```solidity
function plugged(string name, bytes4 salt) external view virtual returns (bool)
```

_see {ICrunaManager.sol-plugged}_

### pluginIndex

```solidity
function pluginIndex(string name, bytes4 salt) external view virtual returns (bool, uint256)
```

_see {ICrunaManager.sol-pluginIndex}_

### isPluginActive

```solidity
function isPluginActive(string name, bytes4 salt) external view virtual returns (bool)
```

_see {ICrunaManager.sol-disablePlugin}_

### listPluginsKeys

```solidity
function listPluginsKeys(bool active) external view virtual returns (bytes8[])
```

_see {ICrunaManager.sol-listPluginsKeys}_

### pseudoAddress

```solidity
function pseudoAddress(string name, bytes4 _salt) external view virtual returns (address)
```

_see {ICrunaManager.sol-pseudoAddress}_

### managedTransfer

```solidity
function managedTransfer(bytes4 pluginNameId, address to) external virtual
```

_See {IProtected721-managedTransfer}._

### protectedTransfer

```solidity
function protectedTransfer(uint256 tokenId, address to, uint256 timestamp, uint256 validFor, bytes signature) external
```

_See {IProtected721-protectedTransfer}._

### _plugin

```solidity
function _plugin(bytes4 nameId_, bytes4 salt) internal view virtual returns (contract CrunaPluginBase)
```

### _pluginAddress

```solidity
function _pluginAddress(bytes4 nameId_, bytes4 salt) internal view virtual returns (address payable)
```

### _nameId

```solidity
function _nameId() internal view virtual returns (bytes4)
```

_Internal function that must be overridden by the contract to
return the name id of the contract_

### _pseudoAddress

```solidity
function _pseudoAddress(string name, bytes4 _salt) internal view virtual returns (address)
```

### _countPlugins

```solidity
function _countPlugins() internal view virtual returns (uint256, uint256)
```

### _disablePlugin

```solidity
function _disablePlugin(uint256 i, bytes8 _key) internal
```

### _reEnablePlugin

```solidity
function _reEnablePlugin(uint256 i, bytes8 _key) internal
```

### _unplugPlugin

```solidity
function _unplugPlugin(uint256 i, bytes4 nameId_, bytes4 salt, bytes8 _key, enum ICrunaManager.PluginChange change) internal
```

### _authorizePluginToTransfer

```solidity
function _authorizePluginToTransfer(bytes4 nameId_, bytes4 salt, bytes8 _key, enum ICrunaManager.PluginChange change, uint256 timeLock) internal virtual
```

### _combineBytes4

```solidity
function _combineBytes4(bytes4 a, bytes4 b) internal pure returns (bytes8)
```

### _isProtected

```solidity
function _isProtected() internal view virtual returns (bool)
```

_Checks if the NFT is protected.
      Must be implemented by the contract using this base contract_

### _isProtector

```solidity
function _isProtector(address protector_) internal view virtual returns (bool)
```

### _canPreApprove

```solidity
function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual returns (bool)
```

_Checks if someone can pre approve an operation.
      Must be implemented by the contract using this base contract
    @param selector The selector of the function being called.
    @param actor The actor being authorized.
    @param signer The signer of the operation (the protector)_

### _plug

```solidity
function _plug(string name, address proxyAddress_, bool canManageTransfer, bool isERC6551Account, bytes4 nameId_, bytes4 salt, bytes8 _key, uint256 requires) internal
```

### _setSignedActor

```solidity
function _setSignedActor(bytes4 _functionSelector, bytes4 role_, address actor, bool status, uint256 timestamp, uint256 validFor, bytes signature, address sender) internal virtual
```

### _emitLockeEvent

```solidity
function _emitLockeEvent(uint256 protectorsCount, bool status) internal virtual
```

### _getKeyAndSalt

```solidity
function _getKeyAndSalt(bytes4 pluginNameId) internal view returns (bytes8, bytes4)
```

### _pluginIndex

```solidity
function _pluginIndex(bytes4 nameId_, bytes4 salt) internal view virtual returns (bool, uint256)
```

### _preValidateAndCheckSignature

```solidity
function _preValidateAndCheckSignature(bytes4 selector, address actor, uint256 extra, uint256 extra2, uint256 extra3, uint256 timestamp, uint256 validFor, bytes signature) internal virtual
```

### _resetPlugin

```solidity
function _resetPlugin(bytes4 nameId_, bytes4 salt) internal virtual
```

### _resetPluginOnTransfer

```solidity
function _resetPluginOnTransfer(bytes4 nameId_, bytes4 salt) internal virtual
```

### _removeLockIfExpired

```solidity
function _removeLockIfExpired(bytes4 nameId_, bytes4 salt) internal virtual
```

### _resetOnTransfer

```solidity
function _resetOnTransfer(bytes4 nameId_, bytes4 salt) internal virtual
```

## CrunaManagerBase

### upgrade

```solidity
function upgrade(address implementation_) external virtual
```

_Upgrade the implementation of the manager
    @param implementation_ The new implementation_

### migrate

```solidity
function migrate(uint256 previousVersion) external virtual
```

_Execute actions needed in a new manager based on the previous version
    @param previousVersion The previous version_

### _version

```solidity
function _version() internal pure virtual returns (uint256)
```

## CrunaManagerProxy

### constructor

```solidity
constructor(address _initialImplementation) public
```

_Constructor
    @param _initialImplementation Address of the initial implementation_

## ICrunaManager

### PluginConfig

_A struct to keep info about plugged and unplugged plugins
     @param proxyAddress The address of the first implementation of the plugin
     @param salt The salt used during the deployment of the plugin.
     It allows to  have multiple instances of the same plugin
     @param timeLock The time lock for when a plugin is temporarily unauthorized from making transfers
     @param canManageTransfer True if the plugin can manage transfers
     @param canBeReset True if the plugin requires a reset when the vault is transferred
     @param active True if the plugin is active
     @param isERC6551Account True if the plugin is an ERC6551 account
     @param trusted True if the plugin is trusted
     @param banned True if the plugin is banned during the unplug process
     @param unplugged True if the plugin has been unplugged_

```solidity
struct PluginConfig {
  address proxyAddress;
  bytes4 salt;
  uint32 timeLock;
  bool canManageTransfer;
  bool canBeReset;
  bool active;
  bool isERC6551Account;
  bool trusted;
  bool banned;
  bool unplugged;
}
```

### PluginElement

_The plugin element
     @param nameId The bytes4 of the hash of the name of the plugin
     All plugins' names must be unique, as well as their bytes4 Ids
     An official registry will be set up to avoid collisions when plugins
     development will be more active. Using the proxy address as a key is
     not viable because plugins can be upgraded and the address can change.
     @param salt The salt of the plugin
     @param active True if the plugin is active_

```solidity
struct PluginElement {
  bytes4 nameId;
  bytes4 salt;
  bool active;
}
```

### PluginChange

_It enumerates the action that can be performed when changing the status of a plugin_

```solidity
enum PluginChange {
  Plug,
  Unplug,
  Disable,
  ReEnable,
  Authorize,
  DeAuthorize,
  UnplugForever,
  Reset
}
```

### EmitLockedEventFailed

```solidity
event EmitLockedEventFailed()
```

_Event emitted when the manager call to the NFT to emit a Locked event fails._

### ProtectorChange

```solidity
event ProtectorChange(address protector, bool status)
```

_Event emitted when the `status` of `protector` changes_

### ProtectorsAndSafeRecipientsImported

```solidity
event ProtectorsAndSafeRecipientsImported(address[] protectors, address[] safeRecipients, uint256 fromTokenId)
```

_Event emitted when protectors and safe recipients are imported from another token_

### SafeRecipientChange

```solidity
event SafeRecipientChange(address recipient, bool status)
```

_Event emitted when the `status` of `recipient` changes_

### PluginStatusChange

```solidity
event PluginStatusChange(string name, bytes4 salt, address pluginAddress, uint256 change)
```

_Event emitted when
the status of plugin identified by `name` and `salt`, and deployed to `pluginAddress` gets a specific `change`_

### Reset

```solidity
event Reset()
```

_Emitted when protectors and safe recipients are removed and all plugins are disabled (if they require it)
This event overrides any specific ProtectorChange, SafeRecipientChange and PluginStatusChange event_

### PluginTrusted

```solidity
event PluginTrusted(string name, bytes4 salt)
```

_Emitted when a plugin initially plugged despite being not trusted, is trusted by the CrunaGuardian_

### ImplementationUpgraded

```solidity
event ImplementationUpgraded(address implementation_, uint256 oldVersion, uint256 newVersion)
```

_Emitted when the implementation of the manager is upgraded
     @param implementation_ The address of the new implementation
     @param oldVersion The old version of the manager
     @param newVersion The new version of the manager_

### PluginResetAttemptFailed

```solidity
event PluginResetAttemptFailed(bytes4 _nameId, bytes4 salt)
```

_Event emitted when the attempt to reset a plugin fails
     When this happens, the token owner can unplug the plugin and mark it as banned to avoid future re-plugs_

### UntrustedImplementation

```solidity
error UntrustedImplementation(address implementation)
```

_Returned when trying to upgrade the manager to an untrusted implementation_

### InvalidVersion

```solidity
error InvalidVersion(uint256 oldVersion, uint256 newVersion)
```

_Returned when trying to upgrade to an older version of the manager_

### PluginRequiresUpdatedManager

```solidity
error PluginRequiresUpdatedManager(uint256 requiredVersion)
```

_Returned when trying to plug a plugin that requires a new version of the manager_

### Forbidden

```solidity
error Forbidden()
```

_Returned when the sender has no right to execute a function_

### NotAManager

```solidity
error NotAManager(address sender)
```

_Returned when the sender is not a manager_

### ProtectorNotFound

```solidity
error ProtectorNotFound(address protector)
```

_Returned when a protector is not found_

### ProtectorAlreadySetByYou

```solidity
error ProtectorAlreadySetByYou(address protector)
```

_Returned when a protector is already set by the sender_

### ProtectorsAlreadySet

```solidity
error ProtectorsAlreadySet()
```

_Returned when a protector is already set_

### CannotBeYourself

```solidity
error CannotBeYourself()
```

_Returned when trying to set themself as a protector_

### NotTheAuthorizedPlugin

```solidity
error NotTheAuthorizedPlugin(address callingPlugin)
```

_Returned when the managed transfer is called not by the right plugin_

### PluginNumberOverflow

```solidity
error PluginNumberOverflow()
```

_Returned when there is no more space for plugins_

### PluginHasBeenMarkedAsNotPluggable

```solidity
error PluginHasBeenMarkedAsNotPluggable()
```

_Returned when the plugin has been banned and marked as not pluggable_

### PluginAlreadyPlugged

```solidity
error PluginAlreadyPlugged()
```

_Returned when a plugin has already been plugged_

### PluginNotFound

```solidity
error PluginNotFound()
```

_Returned when a plugin is not found_

### InconsistentProxyAddresses

```solidity
error InconsistentProxyAddresses(address currentAddress, address proposedAddress)
```

_Returned when trying to plug an unplugged plugin and the address of the implementation differ_

### PluginNotFoundOrDisabled

```solidity
error PluginNotFoundOrDisabled()
```

_Returned when a plugin is not found or is disabled_

### PluginNotDisabled

```solidity
error PluginNotDisabled()
```

_Returned when tryng to re-enable a not-disabled plugin_

### PluginAlreadyDisabled

```solidity
error PluginAlreadyDisabled()
```

_Returned when trying to disable a plugin that is already disabled_

### PluginNotAuthorizedToManageTransfer

```solidity
error PluginNotAuthorizedToManageTransfer()
```

_Returned when a plugin tries to transfer the NFT without authorization_

### PluginAlreadyAuthorized

```solidity
error PluginAlreadyAuthorized()
```

_Returned when a plugin has already been authorized_

### PluginAlreadyUnauthorized

```solidity
error PluginAlreadyUnauthorized()
```

_Returned when a plugin has already been unauthorized_

### NotATransferPlugin

```solidity
error NotATransferPlugin()
```

_Returned when a plugin is not authorized to make transfers_

### InvalidImplementation

```solidity
error InvalidImplementation(bytes4 nameIdReturnedByPlugin, bytes4 proposedNameId)
```

_Returned when trying to plug a plugin that responds to a different nameId_

### InvalidTimeLock

```solidity
error InvalidTimeLock(uint256 timeLock)
```

_Returned when setting an invalid TimeLock when temporarily de-authorizing a plugin_

### InvalidValidity

```solidity
error InvalidValidity()
```

_Returned when calling a function with a validity overflowing the maximum value_

### InvalidERC6551Status

```solidity
error InvalidERC6551Status()
```

_Returned when plugging plugin as ERC6551 while the plugin is not an ERC6551 account, or vice versa_

### UntrustedImplementationsNotAllowedToMakeTransfers

```solidity
error UntrustedImplementationsNotAllowedToMakeTransfers()
```

_Returned when trying to make a transfer with an untrusted plugin, when the NFT accepts only trusted ones_

### StillUntrusted

```solidity
error StillUntrusted()
```

_Returned if trying to trust a plugin that is still untrusted_

### PluginAlreadyTrusted

```solidity
error PluginAlreadyTrusted()
```

_Returned if a plugin has already been trusted_

### CannotImportProtectorsAndSafeRecipientsFromYourself

```solidity
error CannotImportProtectorsAndSafeRecipientsFromYourself()
```

_Returned when trying to import protectors and safe recipients from the token itself_

### NotTheSameOwner

```solidity
error NotTheSameOwner(address originSOwner, address owner)
```

_Returned when the owner of the exporter token is different from the owner of the importer token_

### SafeRecipientsAlreadySet

```solidity
error SafeRecipientsAlreadySet()
```

_Returned when some safe recipients have already been set_

### NothingToImport

```solidity
error NothingToImport()
```

_Returned when the origin token has no protectors and no safe recipients_

### UnsupportedPluginChange

```solidity
error UnsupportedPluginChange()
```

_Returned when trying to change the status of a plugin to an unsupported mode_

### IndexOutOfBounds

```solidity
error IndexOutOfBounds()
```

_Returned when trying to get the index of a plugin in the allPlugins array, but that index is out of bounds_

### ToBeUsedOnlyWhenProtectorsAreActive

```solidity
error ToBeUsedOnlyWhenProtectorsAreActive()
```

_Returned when trying to use a function that requires protectors, but no protectors are set_

### pluginByKey

```solidity
function pluginByKey(bytes8 key) external view returns (struct ICrunaManager.PluginConfig)
```

_It returns the configuration of a plugin by key
     @param key The key of the plugin_

### allPlugins

```solidity
function allPlugins() external view returns (struct ICrunaManager.PluginElement[])
```

_It returns the configuration of all currently plugged plugins_

### pluginByIndex

```solidity
function pluginByIndex(uint256 index) external view returns (struct ICrunaManager.PluginElement)
```

_It returns an element of the array of all plugged plugins
     @param index The index of the plugin in the array_

### migrate

```solidity
function migrate(uint256) external
```

_During an upgrade allows the manager to perform adjustments if necessary.
     The parameter is the version of the manager being replaced. This will allow the
     new manager to know what to do to adjust the state of the new manager._

### findProtectorIndex

```solidity
function findProtectorIndex(address protector_) external view returns (uint256)
```

_Find a specific protector_

### isProtector

```solidity
function isProtector(address protector_) external view returns (bool)
```

_Returns true if the address is a protector.
     @param protector_ The protector address._

### hasProtectors

```solidity
function hasProtectors() external view returns (bool)
```

_Returns true if there are protectors._

### isTransferable

```solidity
function isTransferable(address to) external view returns (bool)
```

_Returns true if the token is transferable (since the NFT is ERC6454)
     @param to The address of the recipient.
     If the recipient is a safe recipient, it returns true._

### locked

```solidity
function locked() external view returns (bool)
```

_Returns true if the token is locked (since the NFT is ERC6982)_

### countProtectors

```solidity
function countProtectors() external view returns (uint256)
```

_Counts how many protectors have been set_

### countSafeRecipients

```solidity
function countSafeRecipients() external view returns (uint256)
```

_Counts the safe recipients_

### setProtector

```solidity
function setProtector(address protector_, bool active, uint256 timestamp, uint256 validFor, bytes signature) external
```

_Set a protector for the token
     @param protector_ The protector address
     @param active True to add a protector, false to remove it
     @param timestamp The timestamp of the signature
     @param validFor The validity of the signature
     @param signature The signature of the protector
     If no signature is required, the field timestamp must be 0
     If the operations has been pre-approved by the protector, the signature should be replaced
     by a shorter (invalid) one, to tell the signature validator to look for a pre-approval._

### importProtectorsAndSafeRecipientsFrom

```solidity
function importProtectorsAndSafeRecipientsFrom(uint256 tokenId) external
```

_Imports protectors and safe recipients from another tokenId owned by the same owner
     It requires that there are no protectors and no safe recipients in the current token, and
     that the origin token has at least one protector or one safe recipient._

### getProtectors

```solidity
function getProtectors() external view returns (address[])
```

_get the list of all protectors_

### setSafeRecipient

```solidity
function setSafeRecipient(address recipient, bool status, uint256 timestamp, uint256 validFor, bytes signature) external
```

_Set a safe recipient for the token, i.e., an address that can receive the token without any restriction
     even when protectors have been set.
     @param recipient The recipient address
     @param status True to add a safe recipient, false to remove it_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address |  |
| status | bool |  |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the protector |

### isSafeRecipient

```solidity
function isSafeRecipient(address recipient) external view returns (bool)
```

_Check if an address is a safe recipient_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The recipient address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the recipient is a safe recipient |

### getSafeRecipients

```solidity
function getSafeRecipients() external view returns (address[])
```

_Gets all safe recipients_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | An array with the list of all safe recipients |

### plug

```solidity
function plug(string name, address pluginProxy, bool canManageTransfer, bool isERC6551Account, bytes4 salt, uint256 timestamp, uint256 validFor, bytes signature) external
```

_It plugs a new plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| pluginProxy | address | The address of the plugin implementation |
| canManageTransfer | bool | True if the plugin can manage transfers |
| isERC6551Account | bool | True if the plugin is an ERC6551 account |
| salt | bytes4 | The salt used during the deployment of the plugin |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the protector |

### changePluginStatus

```solidity
function changePluginStatus(string name, bytes4 salt, enum ICrunaManager.PluginChange change, uint256 timeLock_, uint256 timestamp, uint256 validFor, bytes signature) external
```

_It changes the status of a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin |
| change | enum ICrunaManager.PluginChange | The type of change |
| timeLock_ | uint256 | The time lock for when a plugin is temporarily unauthorized from making transfers |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the protector |

### trustPlugin

```solidity
function trustPlugin(string name, bytes4 salt) external
```

_It trusts a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin No need for a signature by a protector because the safety of the plugin is guaranteed by the CrunaGuardian. |

### pluginAddress

```solidity
function pluginAddress(bytes4 nameId_, bytes4 salt) external view returns (address payable)
```

_It returns the address of a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId_ | bytes4 | The bytes4 of the hash of the name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin The address is returned even if a plugin has not deployed yet. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address payable | The plugin address |

### plugin

```solidity
function plugin(bytes4 nameId_, bytes4 salt) external view returns (contract CrunaPluginBase)
```

_It returns a plugin by name and salt_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nameId_ | bytes4 | The bytes4 of the hash of the name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin The plugin is returned even if a plugin has not deployed yet, which means that it will revert during the execution. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract CrunaPluginBase | The plugin |

### countPlugins

```solidity
function countPlugins() external view returns (uint256, uint256)
```

_It returns the number of plugins_

### plugged

```solidity
function plugged(string name, bytes4 salt) external view returns (bool)
```

_Says if a plugin is currently plugged_

### pluginIndex

```solidity
function pluginIndex(string name, bytes4 salt) external view returns (bool, uint256)
```

_Returns the index of a plugin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | a tuple with a true if the plugin is found, and the index of the plugin |
| [1] | uint256 |  |

### isPluginActive

```solidity
function isPluginActive(string name, bytes4 salt) external view returns (bool)
```

_Checks if a plugin is active_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| salt | bytes4 | The salt used during the deployment of the plugin |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the plugin is active |

### listPluginsKeys

```solidity
function listPluginsKeys(bool active) external view returns (bytes8[])
```

_returns the list of plugins' keys
Since the names of the plugins are not saved in the contract, the app calling for this function
is responsible for knowing the names of all the plugins.
In the future it would be good to have an official registry of all plugins to be able to reverse
from the nameId to the name as a string._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| active | bool | True to get the list of active plugins, false to get the list of inactive plugins |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes8[] | The list of plugins' keys |

### pseudoAddress

```solidity
function pseudoAddress(string name, bytes4 _salt) external view returns (address)
```

_It returns a pseudo address created from the name of a plugin and the salt used to deploy it.
Notice that abi.encodePacked does not risk to create collisions because the salt has fixed length
in the hashed bytes._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the plugin |
| _salt | bytes4 | The salt used during the deployment of the plugin |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The pseudo address of the plugin |

### managedTransfer

```solidity
function managedTransfer(bytes4 pluginNameId, address to) external
```

_A special function that can be called only by authorized plugins to transfer the NFT._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pluginNameId | bytes4 | The bytes4 of the hash of the name of the plugin The plugin must be searched by the pluginNameId and the salt, and the function must verify that the current sender is the plugin. |
| to | address | The address of the recipient |

### protectedTransfer

```solidity
function protectedTransfer(uint256 tokenId, address to, uint256 timestamp, uint256 validFor, bytes signature) external
```

_Allows the user to transfer the NFT when protectors are set_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The id of the token |
| to | address | The address of the recipient |
| timestamp | uint256 | The timestamp of the signature |
| validFor | uint256 | The validity of the signature |
| signature | bytes | The signature of the protector The function should revert if no protectors are set, inviting to use the standard ERC721 transfer functions. |

### upgrade

```solidity
function upgrade(address implementation_) external
```

_Upgrades the implementation of the manager_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation_ | address | The address of the new implementation |

## CrunaPluginBase

### _conf

```solidity
struct ICrunaPlugin.Conf _conf
```

_The internal configuration of the plugin_

### ifMustNotBeReset

```solidity
modifier ifMustNotBeReset()
```

_Verifies that the plugin must not be reset_

### init

```solidity
function init() external
```

_see {ICrunaPlugin.sol-init}_

### manager

```solidity
function manager() external view virtual returns (contract CrunaManager)
```

_see {ICrunaPlugin.sol-manager}_

### version

```solidity
function version() external pure virtual returns (uint256)
```

_see {IVersioned.sol-version}_

### upgrade

```solidity
function upgrade(address implementation_) external virtual
```

_see {ICrunaPlugin.sol-upgrade}_

### resetOnTransfer

```solidity
function resetOnTransfer() external
```

_see {ICrunaPlugin.sol-resetOnTransfer}_

### _canPreApprove

```solidity
function _canPreApprove(bytes4, address, address signer) internal view virtual returns (bool)
```

_Internal function to verify if a signer can pre approve an operation (if the sender is a protector)
    The params:
     - operation The selector of the called function
     - the actor to be approved
     - signer The signer of the operation (the protector)_

### _version

```solidity
function _version() internal pure virtual returns (uint256)
```

_see {IVersioned.sol-version}_

### _isProtected

```solidity
function _isProtected() internal view virtual returns (bool)
```

_internal function to check if the NFT is currently protected_

### _isProtector

```solidity
function _isProtector(address protector) internal view virtual returns (bool)
```

_Internal function to check if an address is a protector
    @param protector The address to check_

## ICrunaPlugin

### Conf

_The configuration of the plugin_

```solidity
struct Conf {
  contract CrunaManager manager;
  uint32 mustBeReset;
}
```

### UntrustedImplementation

```solidity
error UntrustedImplementation(address implementation)
```

_Error returned when the plugin is reset
    @param implementation The address of the new implementation_

### InvalidVersion

```solidity
error InvalidVersion(uint256 oldVersion, uint256 newVersion)
```

_Error returned when the plugin is reset
    @param oldVersion The version of the current implementation
    @param newVersion The version of the new implementation_

### PluginRequiresUpdatedManager

```solidity
error PluginRequiresUpdatedManager(uint256 requiredVersion)
```

_Error returned when the plugin is reset
    @param requiredVersion The version required by the plugin_

### Forbidden

```solidity
error Forbidden()
```

_Error returned when the plugin is reset_

### PluginMustBeReset

```solidity
error PluginMustBeReset()
```

_Error returned when the plugin must be reset before using it_

### init

```solidity
function init() external
```

_Initialize the plugin. It must be implemented, but can do nothing is no init is needed._

### requiresToManageTransfer

```solidity
function requiresToManageTransfer() external pure returns (bool)
```

_Called by the manager during the plugging to know if the plugin is asking the
      right to make a managed transfer of the vault_

### requiresResetOnTransfer

```solidity
function requiresResetOnTransfer() external pure returns (bool)
```

_Called by the manager to know it the plugin must be reset when transferring the NFT_

### isERC6551Account

```solidity
function isERC6551Account() external pure returns (bool)
```

_Called by the manager to know if the plugin is an ERC721 account_

### reset

```solidity
function reset() external
```

_Reset the plugin to the factory settings_

### resetOnTransfer

```solidity
function resetOnTransfer() external
```

### upgrade

```solidity
function upgrade(address implementation_) external
```

_Upgrade the implementation of the manager/plugin
      Notice that the owner can upgrade active or disable plugins
      so that, if a plugin is compromised, the user can disable it,
      wait for a new trusted implementation and upgrade it._

### manager

```solidity
function manager() external view returns (contract CrunaManager)
```

_Returns the manager_

## IInheritanceCrunaPlugin

### InheritanceConf

_Struct to store the configuration for the inheritance
    @param beneficiary The beneficiary address
    @param quorum The number of sentinels required to approve a request
    @param gracePeriodInWeeks The grace period in weeks
    @param proofOfLifeDurationInWeeks The duration of the Proof-of-Live, i.e., the number
      of days after which the sentinels can start the process to inherit the token if the
      owner does not prove to be alive
    @param lastProofOfLife The timestamp of the last Proof-of-Life
    @param extendedProofOfLife The timestamp of the extended Proof-of-Life_

```solidity
struct InheritanceConf {
  address beneficiary;
  uint8 quorum;
  uint8 gracePeriodInWeeks;
  uint8 proofOfLifeDurationInWeeks;
  uint32 lastProofOfLife;
  uint32 extendedProofOfLife;
}
```

### Votes

_Struct to store the votes
    @param nominations The nominated beneficiaries
    @param favorites The favorite beneficiary for each sentinel_

```solidity
struct Votes {
  address[] nominations;
  mapping(address => address) favorites;
}
```

### SentinelUpdated

```solidity
event SentinelUpdated(address owner, address sentinel, bool status)
```

_Emitted when a sentinel is updated
    @param owner The owner address
    @param sentinel The sentinel address
    @param status True if the sentinel is active, false if it is not_

### InheritanceConfigured

```solidity
event InheritanceConfigured(address owner, uint256 quorum, uint256 proofOfLifeDurationInWeeks, uint256 gracePeriodInWeeks, address beneficiary)
```

_Emitted when the inheritance is configured
    @param owner The owner address
    @param quorum The number of sentinels required to approve a request
    @param proofOfLifeDurationInWeeks The duration of the Proof-of-Live, i.e., the number
      of days after which the sentinels can start the process to inherit the token if the
      owner does not prove to be alive
    @param gracePeriodInWeeks The grace period in weeks
    @param beneficiary The beneficiary address_

### ProofOfLife

```solidity
event ProofOfLife(address owner)
```

_Emitted when a Proof-of-Life is triggered
    @param owner The owner address_

### VotedForBeneficiary

```solidity
event VotedForBeneficiary(address sentinel, address beneficiary)
```

_Emitted when a sentinel votes for a beneficiary
    @param sentinel The sentinel address
    @param beneficiary The beneficiary address. If the address == address(0), the vote
      is to retire the beneficiary_

### BeneficiaryApproved

```solidity
event BeneficiaryApproved(address beneficiary)
```

_Emitted when a beneficiary is approved
    @param beneficiary The beneficiary address_

### QuorumCannotBeZero

```solidity
error QuorumCannotBeZero()
```

_Error returned when the quorum is set to 0_

### QuorumCannotBeGreaterThanSentinels

```solidity
error QuorumCannotBeGreaterThanSentinels()
```

_Error returned when the quorum is greater than the number of sentinels_

### InheritanceNotConfigured

```solidity
error InheritanceNotConfigured()
```

_Error returned when the inheritance is not set_

### StillAlive

```solidity
error StillAlive()
```

_Error returned when the owner is still alive, i.e., there is a Proof-of-Life event
      more recent than the Proof-of-Life duration_

### NotASentinel

```solidity
error NotASentinel()
```

_Error returned when the sender is not a sentinel_

### NotTheBeneficiary

```solidity
error NotTheBeneficiary()
```

_Error returned when the sender is not the beneficiary_

### BeneficiaryNotSet

```solidity
error BeneficiaryNotSet()
```

_Error returned when the beneficiary is not set_

### WaitingForBeneficiary

```solidity
error WaitingForBeneficiary()
```

_Error returned when trying to vote for a beneficiary, while
      the grace period for the current beneficiary is not over_

### InvalidValidity

```solidity
error InvalidValidity()
```

_Error returned when passing a signature with a validFor > MAX_VALID_FOR_

### NoVoteToRetire

```solidity
error NoVoteToRetire()
```

_Error returned when trying to retire a not-found vote_

### InvalidParameters

```solidity
error InvalidParameters()
```

_Error returned when the parameters are invalid_

### setSentinel

```solidity
function setSentinel(address sentinel, bool active, uint256 timestamp, uint256 validFor, bytes signature) external
```

_Set a sentinel for the token
    @param sentinel The sentinel address
    @param active True to activate, false to deactivate
    @param timestamp The timestamp of the signature
    @param validFor The validity of the signature
    @param signature The signature of the tokensOwner_

### setSentinels

```solidity
function setSentinels(address[] sentinels, bytes emptySignature) external
```

_Set a list of sentinels for the token
     It is a convenience function to set multiple sentinels at once, but it
     works only if no protectors have been set up. Useful for initial settings.
    @param sentinels The sentinel addresses
    @param emptySignature The signature of the tokensOwner_

### configureInheritance

```solidity
function configureInheritance(uint8 quorum, uint8 proofOfLifeDurationInWeeks, uint8 gracePeriodInWeeks, address beneficiary, uint256 timestamp, uint256 validFor, bytes signature) external
```

_Configures an inheritance
    Some parameters are optional depending on the scenario.
    There are three scenarios:

    - The user sets a beneficiary. The beneficiary can inherit the NFT as soon as a Proof-of-Life is missed.
    - The user sets more than a single sentinel. The sentinels propose a beneficiary, and when the quorum is reached, the beneficiary can inherit the NFT.
    - The user sets a beneficiary and some sentinels. In this case, the beneficiary has a grace period to inherit the NFT. If after that grace period the beneficiary has not inherited the NFT, the sentinels can propose a new beneficiary.

    @param quorum The number of sentinels required to approve a request
    @param proofOfLifeDurationInWeeks The duration of the Proof-of-Live, i.e., the number
     of days after which the sentinels can start the process to inherit the token if the
     owner does not prove to be alive
    @param gracePeriodInWeeks The grace period in weeks
    @param beneficiary The beneficiary address
    @param timestamp The timestamp of the signature
    @param validFor The validity of the signature
    @param signature The signature of the tokensOwner_

### getSentinelsAndInheritanceData

```solidity
function getSentinelsAndInheritanceData() external view returns (address[], struct IInheritanceCrunaPlugin.InheritanceConf)
```

_Return all the sentinels and the inheritance data_

### getVotes

```solidity
function getVotes() external view returns (address[])
```

_Return all the votes_

### countSentinels

```solidity
function countSentinels() external view returns (uint256)
```

_Return the number of sentinels_

### proofOfLife

```solidity
function proofOfLife() external
```

_allows the user to trigger a Proof-of-Live_

### voteForBeneficiary

```solidity
function voteForBeneficiary(address beneficiary) external
```

_Allows the sentinels to nominate a beneficiary
   @param beneficiary The beneficiary address
     If the beneficiary is address(0), the vote is to retire a previously voted beneficiary_

### inherit

```solidity
function inherit() external
```

_Allows the beneficiary to inherit the token_

## InheritanceCrunaPlugin

### _inheritanceConf

```solidity
struct IInheritanceCrunaPlugin.InheritanceConf _inheritanceConf
```

_The object storing the inheritance configuration_

### _votes

```solidity
struct IInheritanceCrunaPlugin.Votes _votes
```

_The object storing the votes_

### requiresToManageTransfer

```solidity
function requiresToManageTransfer() external pure returns (bool)
```

_see {IInheritanceCrunaPlugin.sol-requiresToManageTransfer}_

### isERC6551Account

```solidity
function isERC6551Account() external pure virtual returns (bool)
```

_see {IInheritanceCrunaPlugin.sol-isERC6551Account}_

### setSentinel

```solidity
function setSentinel(address sentinel, bool status, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

_see {IInheritanceCrunaPlugin.sol-setSentinel}_

### setSentinels

```solidity
function setSentinels(address[] sentinels, bytes emptySignature) external virtual
```

_see {IInheritanceCrunaPlugin.sol-setSentinels}_

### configureInheritance

```solidity
function configureInheritance(uint8 quorum, uint8 proofOfLifeDurationInWeeks, uint8 gracePeriodInWeeks, address beneficiary, uint256 timestamp, uint256 validFor, bytes signature) external virtual
```

_see {IInheritanceCrunaPlugin.sol-configureInheritance}_

### countSentinels

```solidity
function countSentinels() external view virtual returns (uint256)
```

_see {IInheritanceCrunaPlugin.sol-countSentinels}_

### getSentinelsAndInheritanceData

```solidity
function getSentinelsAndInheritanceData() external view virtual returns (address[], struct IInheritanceCrunaPlugin.InheritanceConf)
```

_see {IInheritanceCrunaPlugin.sol-getSentinelsAndInheritanceData}_

### getVotes

```solidity
function getVotes() external view virtual returns (address[])
```

_see {IInheritanceCrunaPlugin.sol-getVotes}_

### proofOfLife

```solidity
function proofOfLife() external virtual
```

_see {IInheritanceCrunaPlugin.sol-proofOfLife}_

### voteForBeneficiary

```solidity
function voteForBeneficiary(address beneficiary) external virtual
```

_see {IInheritanceCrunaPlugin.sol-voteForBeneficiary}_

### inherit

```solidity
function inherit() external virtual
```

_see {IInheritanceCrunaPlugin.sol-inherit}_

### reset

```solidity
function reset() external
```

_see {ICrunaPlugin.sol-reset}_

### requiresResetOnTransfer

```solidity
function requiresResetOnTransfer() external pure returns (bool)
```

_see {ICrunaPlugin.sol-requiresResetOnTransfer}_

### _nameId

```solidity
function _nameId() internal pure virtual returns (bytes4)
```

_see {CrunaPluginBase.sol-_nameId}_

### _setSentinel

```solidity
function _setSentinel(address sentinel, bool status, uint256 timestamp, uint256 validFor, bytes signature) internal virtual
```

_It sets a sentinel
    @param sentinel The sentinel address
    @param status True if the sentinel is active, false if it is not
    @param timestamp The timestamp
    @param validFor The validity of the signature
    @param signature The signature_

### _configureInheritance

```solidity
function _configureInheritance(uint8 quorum, uint8 proofOfLifeDurationInWeeks, uint8 gracePeriodInWeeks, address beneficiary) internal virtual
```

### _quorumReached

```solidity
function _quorumReached() internal view virtual returns (address)
```

### _isNominated

```solidity
function _isNominated(address beneficiary) internal view virtual returns (bool)
```

### _popNominated

```solidity
function _popNominated(address beneficiary) internal virtual
```

### _resetNominationsAndVotes

```solidity
function _resetNominationsAndVotes() internal virtual
```

### _isASentinel

```solidity
function _isASentinel() internal view virtual returns (bool)
```

### _checkIfStillAlive

```solidity
function _checkIfStillAlive() internal view virtual
```

### _isGracePeriodExpiredForBeneficiary

```solidity
function _isGracePeriodExpiredForBeneficiary() internal virtual returns (bool)
```

### _reset

```solidity
function _reset() internal
```

## InheritanceCrunaPluginProxy

### constructor

```solidity
constructor(address _initialImplementation) public
```

_Constructor
    @param _initialImplementation Address of the initial implementation_

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

_allows only the manager of a certain tokenId to call the function.
    @param tokenId The id of the token._

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

_internal function to return the manager (for lesser gas consumption)
    @param tokenId the id of the token
    @return the address of the manager_

### _defaultManagerImplementation

```solidity
function _defaultManagerImplementation(uint256 _tokenId) internal view virtual returns (address)
```

_Returns the default implementation of the manager for a specific tokenId
    @param _tokenId the tokenId
    @return The address of the implementation_

### _addressOfDeployed

```solidity
function _addressOfDeployed(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) internal view virtual returns (address)
```

_Internal function to return the address of a deployed token bound contract
    @param implementation The address of the implementation
    @param salt The salt
    @param tokenId The tokenId
    @param isERC6551Account If true, the tokenId has been deployed via ERC6551Registry, if false, via CrunaRegistry_

### _canManage

```solidity
function _canManage(bool isInitializing) internal view virtual
```

_Specify if the caller can call some function.
      Must be overridden to specify who can manage changes during initialization and later
     @param isInitializing If true, the function is being called during initialization, if false,
      it is supposed to the called later. A time controlled NFT can allow the admin to call some
      functions during the initialization, requiring later a standard proposal/execition process._

### _update

```solidity
function _update(address to, uint256 tokenId, address auth) internal virtual returns (address)
```

_See {ERC721-_update}._

### _isTransferable

```solidity
function _isTransferable(uint256 tokenId, address from, address to) internal view virtual returns (bool)
```

_Function to define a token as transferable or not, according to IERC6454
    @param tokenId The id of the token.
    @param from The address of the sender.
    @param to The address of the recipient.
    @return true if the token is transferable, false otherwise._

### _mintAndActivateByAmount

```solidity
function _mintAndActivateByAmount(address to, uint256 amount) internal virtual
```

_Mints tokens by amount.
      It works only if nftConf.progressiveTokenIds is true.
    @param to The address of the recipient.
    @param amount The amount of tokens to mint._

### _mintAndActivate

```solidity
function _mintAndActivate(address to, uint256 tokenId) internal virtual
```

_This function will mint a new token and initialize it.
      Use it carefully if nftConf.progressiveTokenIds is true. Usually, used to
      reserve some specific token to the project itself, the DAO, etc.
    @param to The address of the recipient.
    @param tokenId The id of the token._

### _deploy

```solidity
function _deploy(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) internal virtual returns (address)
```

_This function deploys a token-bound contract (manager or plugin)
    @param implementation The address of the implementation
    @param salt The salt
    @param tokenId The tokenId
    @param isERC6551Account If true, the tokenId will be deployed via ERC6551Registry,
      if false, via CrunaRegistry_

## CrunaProtectedNFTOwnable

### NotTheOwner

```solidity
error NotTheOwner()
```

_Error returned when the caller is not the owner_

### constructor

```solidity
constructor(string name_, string symbol_, address admin) internal
```

_Construct the contract with a given name, symbol, and admin.
    @param name_ The name of the token.
    @param symbol_ The symbol of the token.
    @param admin The owner of the contract_

### _canManage

```solidity
function _canManage(bool) internal view virtual
```

_see {CrunaProtectedNFT-_canManage}_

## CrunaProtectedNFTTimeControlled

### NotAuthorized

```solidity
error NotAuthorized()
```

_Error returned when the caller is not authorized_

### constructor

```solidity
constructor(string name_, string symbol_, uint256 minDelay, address[] proposers, address[] executors, address admin) internal
```

_construct the contract with a given name, symbol, minDelay, proposers, executors, and admin.
    @param name_ The name of the token.
    @param symbol_ The symbol of the token.
    @param minDelay The minimum delay for the time lock.
    @param proposers The initial proposers.
    @param executors The initial executors.
    @param admin The admin of the contract (they should later renounce to the role)._

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

### _canManage

```solidity
function _canManage(bool isInitializing) internal view virtual
```

_see {CrunaProtectedNFT-_canManage}_

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

_Emitted when the default manager is upgraded
    @param newManagerProxy The address of the new manager proxy_

### MaxTokenIdChange

```solidity
event MaxTokenIdChange(uint112 maxTokenId)
```

_Emitted when the maxTokenId is changed
    @param maxTokenId The new maxTokenId_

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

_Returns the manager history for a specific index
    @param index The index_

### setMaxTokenId

```solidity
function setMaxTokenId(uint112 maxTokenId_) external
```

_set the maximum tokenId that can be minted
    @param maxTokenId_ The new maxTokenId_

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

_Initialize the NFT
    @param managerAddress_ The address of the manager
    @param progressiveTokenIds_ If true, the tokenIds will be progressive
    @param allowUntrustedTransfers_ If true, the token will allow untrusted plugins to transfer the tokens
    @param nextTokenId_ The next tokenId to be used
    @param maxTokenId_ The maximum tokenId that can be minted (it can be 0 if no upper limit)_

### defaultManagerImplementation

```solidity
function defaultManagerImplementation(uint256 _tokenId) external view returns (address)
```

_Returns the address of the default implementation of the manager for a tokenId
    @param _tokenId The tokenId_

### upgradeDefaultManager

```solidity
function upgradeDefaultManager(address payable newManagerProxy) external
```

_Upgrade the default manager for any following tokenId
    @param newManagerProxy The address of the new manager proxy_

### managerOf

```solidity
function managerOf(uint256 tokenId) external view returns (address)
```

_Return the address of the manager of a tokenId
    @param tokenId The id of the token._

### deployPlugin

```solidity
function deployPlugin(address pluginImplementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external returns (address)
```

_Deploys a plugin
    @param pluginImplementation The address of the plugin implementation
    @param salt The salt
    @param tokenId The tokenId
    @param isERC6551Account Specifies the registry to use
      True if the tokenId must be deployed via ERC6551Registry,
      false, it must be deployed via CrunaRegistry_

### isDeployed

```solidity
function isDeployed(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external view returns (bool)
```

_Returns if a plugin is deployed
    @param implementation The address of the plugin implementation
    @param salt The salt
    @param tokenId The tokenId
    @param isERC6551Account Specifies the registry to use
      True if the tokenId was deployed via ERC6551Registry,
      false, it was deployed via CrunaRegistry_

## IManagedNFT

### ManagedTransfer

```solidity
event ManagedTransfer(bytes4 pluginNameId, uint256 tokenId)
```

_Emitted when a token is transferred by a plugin
    @param pluginNameId The hash of the plugin name.
    @param tokenId The id of the token._

### managedTransfer

```solidity
function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external
```

_Allow a plugin to transfer the token
    @param pluginNameId The hash of the plugin name.
    @param tokenId The id of the token.
    @param to The address of the recipient._

## CommonBase

### _IMPLEMENTATION_SLOT

```solidity
bytes32 _IMPLEMENTATION_SLOT
```

_Storage slot with the address of the current implementation.
     This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     validated in the constructor._

### onlyTokenOwner

```solidity
modifier onlyTokenOwner()
```

_Error returned when the caller is not the token owner_

### nameId

```solidity
function nameId() external view returns (bytes4)
```

_Returns the name id of the contract_

### _nameId

```solidity
function _nameId() internal view virtual returns (bytes4)
```

_Internal function that must be overridden by the contract to
return the name id of the contract_

### vault

```solidity
function vault() external view virtual returns (contract CrunaProtectedNFT)
```

_Returns the vault, i.e., the CrunaProtectedNFT contract_

### _hashString

```solidity
function _hashString(string input) internal pure returns (bytes32 result)
```

_Returns the keccak256 of a string variable.
     It saves gas compared to keccak256(abi.encodePacked(string)).
     @param input The string to hash_

### _stringToBytes4

```solidity
function _stringToBytes4(string str) internal pure returns (bytes4)
```

_Returns the equivalent of bytes4(keccak256(str).
    @param str The string to hash_

### _vault

```solidity
function _vault() internal view virtual returns (contract CrunaProtectedNFT)
```

_Returns the vault, i.e., the CrunaProtectedNFT contract_

## ERC6551AccountProxy

### DEFAULT_IMPLEMENTATION

```solidity
address DEFAULT_IMPLEMENTATION
```

_The default implementation of the contract_

### InvalidImplementation

```solidity
error InvalidImplementation()
```

_Error returned when the implementation is invalid_

### receive

```solidity
receive() external payable virtual
```

_The function that allows to receive ether and generic calls_

### constructor

```solidity
constructor(address _defaultImplementation) public
```

_Constructor
    @param _defaultImplementation The default implementation of the contract_

### _implementation

```solidity
function _implementation() internal view virtual returns (address)
```

_Returns the implementation of the contract_

### _fallback

```solidity
function _fallback() internal virtual
```

_Fallback function that redirect all the calls not in this proxy to the implementation_

## ICommonBase

### NotTheTokenOwner

```solidity
error NotTheTokenOwner()
```

_Error returned when the caller is not the token owner_

### vault

```solidity
function vault() external view returns (contract CrunaProtectedNFT)
```

_Returns the vault, i.e., the CrunaProtectedNFT contract_

## INamed

### nameId

```solidity
function nameId() external view returns (bytes4)
```

_Returns the name id of the contract_

## INamedAndVersioned

_Combines INamed and IVersioned_

## ISignatureValidator

### PreApproved

```solidity
event PreApproved(bytes32 hash, address signer)
```

_Emitted when a signature is pre-approved.
    @param hash The hash of the signature.
    @param signer The signer of the signature._

### TimestampInvalidOrExpired

```solidity
error TimestampInvalidOrExpired()
```

_Error returned when a timestamp is invalid or expired._

### NotAuthorized

```solidity
error NotAuthorized()
```

_Error returned when a called in unauthorized._

### NotPermittedWhenProtectorsAreActive

```solidity
error NotPermittedWhenProtectorsAreActive()
```

_Error returned when trying to call a protected operation without a valid signature_

### WrongDataOrNotSignedByProtector

```solidity
error WrongDataOrNotSignedByProtector()
```

_Error returned when the signature is not valid._

### SignatureAlreadyUsed

```solidity
error SignatureAlreadyUsed()
```

_Error returned when the signature is already used._

### preApprovals

```solidity
function preApprovals(bytes32 hash) external view returns (address)
```

_Returns the address who approved a pre-approved operation.
    @param hash The hash of the operation._

### hashSignature

```solidity
function hashSignature(bytes signature) external pure returns (bytes32)
```

_Returns the hash of a signature.
    @param signature The signature._

### isSignatureUsed

```solidity
function isSignatureUsed(bytes32 hash) external view returns (bool)
```

_Returns if a signature has been used.
    @param hash The hash of the signature._

### recoverSigner

```solidity
function recoverSigner(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation, bytes signature) external view returns (address, bytes32)
```

_This function validates a signature trying to be as flexible as possible.
      As long as called inside the same contract, the cost adding some more parameters is negligible.
      Instead, calling it from other contracts can be expensive.
    @param selector The selector of the function being called.
    @param owner The owner of the token.
    @param actor The actor being authorized.
     It can be address(0) if the parameter is not needed.
    @param tokenAddress The address of the token.
    @param tokenId The id of the token.
    @param extra The extra
    @param extra2 The extra2
    @param extra3 The extra3
    @param timeValidation A combination of timestamp and validity of the signature.
    @return The signer of the signature and the hash of the signature._

### preApprove

```solidity
function preApprove(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation) external
```

_Pre-approve a signature.
    @param selector The selector of the function being called.
    @param owner The owner of the token.
    @param actor The actor being authorized.
     It can be address(0) if the parameter is not needed.
    @param tokenAddress The address of the token.
    @param tokenId The id of the token.
    @param extra The extra
    @param extra2 The extra2
    @param extra3 The extra3
    @param timeValidation A combination of timestamp and validity of the signature._

## ITokenLinkedContract

### token

```solidity
function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId)
```

_Returns the token linked to the contract
    @return chainId The chainId of the token
    @return tokenContract The address of the token contract
    @return tokenId The tokenId of the token_

### owner

```solidity
function owner() external view returns (address)
```

_Returns the owner of the token_

### tokenAddress

```solidity
function tokenAddress() external view returns (address)
```

_Returns the address of the token contract_

### tokenId

```solidity
function tokenId() external view returns (uint256)
```

_Returns the tokenId of the token_

### implementation

```solidity
function implementation() external view returns (address)
```

_Returns the implementation used when creating the contract_

## SignatureValidator

### _MAX_VALID_FOR

```solidity
uint256 _MAX_VALID_FOR
```

_The maximum validFor. If more than this it will conflict with the timestamp._

### _TIMESTAMP_MULTIPLIER

```solidity
uint256 _TIMESTAMP_MULTIPLIER
```

_The multiplier for the timestamp in the timeValidation parameter._

### constructor

```solidity
constructor() internal
```

_EIP712 constructor_

### preApprovals

```solidity
function preApprovals(bytes32 hash) external view returns (address)
```

_See {ISignatureValidator.sol-preApprovals}_

### hashSignature

```solidity
function hashSignature(bytes signature) external pure returns (bytes32)
```

_see {ISignatureValidator.sol-hashSignature}_

### isSignatureUsed

```solidity
function isSignatureUsed(bytes32 hash) external view returns (bool)
```

_see {ISignatureValidator.sol-isSignatureUsed}_

### recoverSigner

```solidity
function recoverSigner(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation, bytes signature) public view returns (address, bytes32)
```

_see {ISignatureValidator-recoverSigner}_

### preApprove

```solidity
function preApprove(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation) external
```

_see {ISignatureValidator-preApprove}_

### _canPreApprove

```solidity
function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual returns (bool)
```

_Checks if someone can pre approve an operation.
      Must be implemented by the contract using this base contract
    @param selector The selector of the function being called.
    @param actor The actor being authorized.
    @param signer The signer of the operation (the protector)_

### _validate

```solidity
function _validate(uint256 timeValidation) internal view
```

_Validates the timeValidation parameter.
    @param timeValidation The timeValidation parameter_

### _isProtected

```solidity
function _isProtected() internal view virtual returns (bool)
```

_Checks if the NFT is protected.
      Must be implemented by the contract using this base contract_

### _isProtector

```solidity
function _isProtector(address protector) internal view virtual returns (bool)
```

_Checks if an address is a protector.
      Must be implemented by the contract using this base contract_

### _validateAndCheckSignature

```solidity
function _validateAndCheckSignature(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation, bytes signature) internal virtual
```

_Validates and checks the signature.
    @param selector The selector of the function being called.
    @param owner The owner of the token.
    @param actor The actor being authorized.
    @param tokenAddress The address of the token.
    @param tokenId The id of the token.
    @param extra The extra
    @param extra2 The extra2
    @param extra3 The extra3
    @param timeValidation A combination of timestamp and validity of the signature.
    @param signature The signature._

### _hashData

```solidity
function _hashData(bytes4 selector, address owner, address actor, address tokenAddress, uint256 tokenId, uint256 extra, uint256 extra2, uint256 extra3, uint256 timeValidation) internal pure returns (bytes32)
```

_Hashes the data.
    @param selector The selector of the function being called.
    @param owner The owner of the token.
    @param actor The actor being authorized.
    @param tokenAddress The address of the token.
    @param tokenId The id of the token.
    @param extra The extra
    @param extra2 The extra2
    @param extra3 The extra3
    @param timeValidation A combination of timestamp and validity of the signature._

### _hashBytes

```solidity
function _hashBytes(bytes signature) internal pure returns (bytes32 hash)
```

_Util to hash the bytes of the signature saving gas in comparison with using keccak256.
    @param signature The signature._

## TokenLinkedContract

### token

```solidity
function token() public view virtual returns (uint256, address, uint256)
```

_Returns the token linked to the contract_

### owner

```solidity
function owner() public view virtual returns (address)
```

_Returns the owner of the token_

### tokenAddress

```solidity
function tokenAddress() public view virtual returns (address)
```

_Returns the address of the token contract_

### tokenId

```solidity
function tokenId() public view virtual returns (uint256)
```

_Returns the tokenId of the token_

### implementation

```solidity
function implementation() public view virtual returns (address)
```

_Returns the implementation used when creating the contract_

