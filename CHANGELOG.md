# Change log

**0.1.9**
- Minor change in `CrunaProtectedNFT`

**0.1.8**
- In manager, add `unplug` to unplug a plugin and delete any local variable
- Remove `resetPlugin` from `disablePlugin` and `reEnablePlugin`
- Resolve some low security issues
- Optimize gas usage

**0.1.7**
- Modify signature of init function in `CrunaProtectedNFT` to give more flexibility to override the default implementation if needed

**0.1.6**
- Add check to avoid double initializations in `CrunaProtectedNFT`

**0.1.5**
- Align `ManagedHistory` fields to `NFTConf` fields (uint256 > uint112)

**0.1.4**
- improve `_mintAndActivate` in `CrunaProtectedNFT`

**0.1.3**
- improve `setMaxTokenId` in `CrunaProtectedNFT`

**0.1.2**
- allow protected NFTs to mint specific tokens, instead of forcing a sequential minting

**0.1.1**
- fix install instructions in README

**0.1.0**
- moving the repo from cruna-cc to crunaprotocol

**1.0.0-rc.14**
- remove `setProtectors` from manager because it can cause misuses that can lead to losses

**1.0.0-rc.13**
- Fix `bin/publish.sh` — it was not copying the right canonical contracts before publishing.

**1.0.0-rc.10**
- Fix canonical addresses and deploy bytecodes to avoid that changes in the dependencies alters the addresses of the canonical contracts

**1.0.0-rc.9**
- `CrunaPluginBase` extends now `SignatureValidator`

**1.0.0-rc.8**
- Non-blocking approach to beneficiary nominations in `InheritanceCrunaPlugin`

**1.0.0-rc.7**
- Rename `CrunaManagedNFT` to `CrunaProtectedNFT` for clarity

**1.0.0-rc.6**
- Add `importProtectorsAndSafeRecipientsFrom` function to allow to import protectors and safe recipients from another manager owned by the same owner, if and only if the new tokenId has no protectors and safe recipients

**1.0.0-rc.5**
- Add `setProtectors` function to allow to quickly set many protectors in one transaction, but only if no protectors are already set

**1.0.0-rc.4**
- Add flag to specify that a vault has been deployed to a main network since it is not possible to know that on chain
- Allow developers to plug untrusted plugins. This is essential for testing, and useful to test plugins on testnets before deploying them on mainnet
- To avoid security issues, transfers by untrusted plugins can be executed only on testnets

**1.0.0-rc.3**
- Plugins are now deployed by the NFT, not by the manager. This avoids issues when deploying plugins that supports `IERC6551Account` 
- Canonical addresses for `CrunaRegistry`, `CrunaGuardian` and `ERC6551Registry` are now constant and hardcoded
- Add more features in `SignatureValidator` to generalize common operations

**1.0.0-rc.2**
- Fix bug in `CrunaProtectedNFTBase`#init

**1.0.0-rc.1**
- Add support for multi-sig and `ERC4337` wallets as protectors. Since they cannot sign a valid typed_v4 signature, they must pre-approve the operation
- Add firstTokenId to the init function of a CrunaProtectedNFT to allow the owner to set the first tokenId (essential to define cross/multi-chain strategies)

**1.0.0-beta.10**
- After extensive testing we verified that the global emitters were requiring too much gas because of the many external calls with many parameters across contracts
- Removed activation after minting in favor of activation only during the minting process. Still, any implementer can extend the contract to allow for activation after minting, if needed

**1.0.0-beta.9**
- Allow to update the emitters for managers and plugins
- Minor refactoring

**1.0.0-beta.8**
- Relevant events emitted from the single manager are hard to listen to. In this version, the emitter is the proxy implemented by the registry when creating a manager or a plugin for a specific token ID.

**1.0.0-beta.7**
- Add common event emitters for managers, instead of emitting via the vault, to allow the manager to evolve independently from the vault

**1.0.0-beta.6**
- Require signature, if protectors are active, to plug a new plugin, disable and re-enable a plugin, and to authorize/de-authorize a plugin to transfer the NFT
- Minor alignment of function signatures, keeping timeValidation as an internal parameter, in favor of timestamp and validFor

**1.0.0-beta-5**
- Move events like `ProtectorChange`, `SafeRecipientChange`, etc. from the Manager to the Vault, because listening to events emitted by the vault is simpler than listening to the events emitted by all the managers

**1.0.0-beta.4**
- Renaming contracts to better distinguish them
- Add a function to allow a CrunaManaged NFT to upgrade the default implementation of the CrunaManager to a new version
- Simplify proxies
- Split `ManagedERC721` in a basic contract, `CrunaManagedBase`, and two implementations based on `Ownable` and `TimeControlled`. The second is used by `TimeControlledNFT`, but the other can be chosen by less critical projects.
- Extend `TimeControlled` also in the Guardian, to guarantee the fairness of the trusted implementations 

**1.0.0-beta.3**
- Better interface organization
- Move contracts used only for testing to the mocks folder
- Add Time Lock to Guardian

**1.0.0-beta.2**
- Fix typo in `CrunaRegistry` function name
- Reorganize folders and files
- Add function to check if plugins needs to be reset on vault transfer

**1.0.0-beta.1**
- Improve the function `authorizePluginToTransfer` so that it disallows only temporarily a plugin to transfer the NFT 

**1.0.0-beta.0**
- Add views to manager to be able to see which plugins are active, disabled, etc.
- Add maxTokenId to `ManagedERC721` to set a cap to the minting of tokens
- Improved tests, adding calculations for gasLimit when buying vaults

**1.0.0-alpha.7**
- A signature is required also to set the first protector to avoid to risk of setting a protector that is unable to sign the requests

**1.0.0-alpha.6**

- Decouples the minting of a vault from its activation
- Add `activate` to later activate the vault, creating a manager for the tokenId

**1.0.0-alpha.5**

- Fixes the risk that there are too many plugins, and it becomes impossible to disable them all
- Renames ProtectedNFT to ManagedERC721

**1.0.0-alpha.4**

- Optimize costs during signature validation
- Increase security giving more control to the Manager
- Moving sentinels storage to the plugin, instead of the manager, to avoid reentrancy risks


**1.0.0-alpha.3**

- Add function to disable and re-enable plugins
- Making inheritance settable when protectors are active
- Add extra params function to SignatureValidator to be used by plugins

**1.0.0-alpha.2**

- Improve the InheritancePlugin to allow the owner explicitly nominate a beneficiary, in addition to the sentinels

**1.0.0-alpha.1**

- Optimize gas usage minting a new NFT and adding a new plugin

**1.0.0-alpha.1**

- First version of the new protocol. The first one, published as @cruna/cruna-protocol, has been deprecated.
