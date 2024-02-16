# Welcome to the Cruna Protocol - Redefining NFTs for Enhanced Security and Limitless Expandability

Dive into the realm of Cruna Protocol, a revolutionary advancement reshaping the landscape of Non-Fungible Tokens (NFTs). Cruna Protocol transcends traditional NFT functionalities, offering an innovative fusion of security and adaptability. At the heart of our protocol are the Cruna Vault tokens, a new class of Protected NFTs, ingeniously engineered to fortify digital asset management while maintaining unparalleled flexibility.

Our protocol is adeptly designed to synergize with ERC-6551 smart wallets, setting a new standard for asset security. Cruna Vaults, working alongside ERC-6551, create a dynamic ecosystem where NFTs not only hold value but also actively secure and manage it with unparalleled efficiency.

Through the Cruna Protocol, NFTs evolve beyond static assets, transforming into expandable, secure entities capable of owning and interacting with a wide range of digital assets and applications. This shift marks a groundbreaking leap in NFT technology, opening doors to endless possibilities in the digital asset space.

Join us as we explore the forefront of NFT innovation, where security meets scalability, and every digital asset gains the power to be more than just a token – a safeguarded, expandable asset in the ever-evolving digital world.

## Cruna Vault + ERC-6551: A Game-Changer in Asset Security

ERC-6551 defines a system which assigns EVM-compatible accounts to all non-fungible tokens. These token bound accounts allow NFTs to own assets and interact with applications, without requiring changes to existing smart contracts or infrastructure.

While the ERC-6551 standard is a significant step forward in the evolution of NFTs, it lacks a critical component: security. The standard does not specify any security requirements for the NFT to whom the account is bound. This omission leaves the NFT vulnerable to unauthorized access and misuse, undermining the security of the entire system.

Cruna Vault is specially designed to work with ERC-6551 wallets, a new way for NFTs to manage digital assets seamlessly.

### Meet the Protectors

Protectors are like personal guardians for your NFT. As an NFT owner, you can appoint one or more Protectors who must approve any transfer or change. This dual-level security means even if your account is compromised, your NFT stays safe. For added convenience in specific scenarios, like in a company setting, you can set up special rules where certain transfers don't need Protector approval.

Once you set up your first Protector, adding or removing others requires approval too, ensuring no single person can make unilateral changes. This setup is ideal for those who value robust security in managing their digital assets.

_It is advisable to assign multiple Protectors to maintain access to the vault even if one Protector becomes inaccessible. Reasonably, someone may use their hot wallet to buy the NFT and one or more hard wallets as protectors. A company, most likely, would use a multisig wallet as protector._

### Sentinels and Asset Recovery

Imagine a system that safeguards your assets even if you lose access or in case of unforeseen life events. That's what Sentinels do in Cruna Vault. They work on a Proof-of-Life system – you periodically signal that you're still in control. If you can't, Sentinels can start a process to pass your assets to a chosen Beneficiary.

This feature is not just about security; it's about peace of mind and ensuring your digital legacy is preserved and passed on as intended.

## Cruna Vault Plugin Architecture

The Cruna Protocol introduces a flexible Plugin Architecture with every Cruna Vault minted. Alongside the Vault, a Manager contract owned by the Vault is deployed, acting as the central hub for managing various functionalities.

### Manager's Role
The Manager plays a key role in overseeing crucial aspects of the Vault:

* Protectors and Safe Recipients: It handles the appointment and management of Protectors and Safe Recipients, ensuring robust security mechanisms.
* Plugin Management: The Manager is also in charge of managing the Vault’s plugins. For instance, functionalities like Sentinels and Beneficiaries are handled by the InheritancePlugin, a specialized plugin within the system.
### Plugin Integration and Verification
When users want to enhance their Vault with additional features, they can integrate plugins into the Manager:

* Implementation Approval: Before a plugin is activated, its implementation is thoroughly vetted and approved by the Manager.
* Proxy Deployment: Upon approval, the Manager deploys a proxy for the plugin, seamlessly integrating it with the Vault’s ecosystem.
### Ownership and Control
Despite the integration of various plugins, the ultimate control and ownership remain with the Cruna Vault owner:

* Sole Authority: The Vault owner is the exclusive authority over the plugin, retaining complete control over its functionalities.
### Advantages of the Plugin Architecture
This architecture offers significant benefits in terms of scalability and flexibility:

* Seamless Upgradability: It enables the addition of new features to Cruna Vaults without altering the core contract code, ensuring a smooth upgradation path.
* Compatibility with Token Bound Accounts: The architecture ensures that any Token Bound Account (TBA) set for the Cruna Vault remains compatible with new features, eliminating the need for contract migrations or TBA modifications.

## Real-World Applications with ERC-6551

Cruna Vault's flexibility means it can be used in various ways:

* **Asset Consolidation**: Easily transfer a collection of assets in one go.
* **Asset Bundle**s: Group assets for sale as a single NFT.
* **Scheduled Distribution**: Use it for distributing assets over time, like to investors or team members.
* **DAO Management**: Manage collective DAO assets efficiently.
* **Family Asset Management**: Set up assets for your children and transfer them easily when the time comes.
* **Business Reserves**: Safeguard company assets with a secure and recoverable system.

## Other Use Cases for Cruna Vault

### White-Labeled NFT Security Enhancement

Cruna Vault isn't just limited to ERC-6551 integrations; it offers a robust foundation for white-labeled NFTs aiming to boost their security, regardless of their association with ERC-6551. This makes Cruna Vault an ideal choice for NFT creators and platforms seeking to offer enhanced security features under their own brand.

**For NFT Creators and Platforms:**

* **Customizable Security**: Tailor Cruna Vault's robust security features, like Protectors and Sentinels, to fit the unique needs of your NFT project or platform.
* **Brand Integration**: Seamlessly integrate Cruna Vault's functionalities into your NFTs while maintaining your brand identity.
* **Trust and Assurance**: Offer your users and collectors an added layer of security, increasing trust and value in your NFT offerings.

**For Collectors and Investors:**

* **Enhanced Protection**: Benefit from advanced security features, safeguarding your valuable NFTs against unauthorized access and loss.
* **Legacy Planning**: Utilize Cruna Vault's asset recovery and inheritance features to ensure your digital assets are managed according to your wishes, even in unforeseen circumstances.

### Broadening the Scope of Digital Asset Security

Cruna Vault's adaptable architecture makes it suitable for a wide range of applications, transcending traditional NFT use cases:

* **Art and Collectibles**: Secure high-value digital art and collectibles, ensuring they remain protected and retain their value over time.
* **Gaming and Virtual Assets**: Enhance the security of in-game assets or virtual goods, providing players with peace of mind for their digital possessions.
* **Real Estate and Tokenized Assets**: Apply Cruna Vault to tokenized real estate or other significant digital assets, offering a new level of security in the evolving digital asset landscape.

In summary, Cruna Vault's flexibility and advanced security features open up a world of possibilities, not only for ERC-6551 related applications but also for a wide array of digital assets, offering enhanced protection and legacy planning. Whether it's for individual collectors, NFT platforms, or diverse digital asset markets, Cruna Vault stands as a beacon of security and trust in the digital world.

## Smart Contract Upgradeability

While smart contract upgradeability is beneficial, it poses security risks, such as the potential for deploying malicious updates. To prevent this, all contracts, including the Manager and any associated plugins, are immutable, safeguarding against unauthorized alterations.

Despite this, user-driven upgrades are essential. To achieve this, Cruna Protocol utilizes the approach outlined in ERC-6551. This involves deploying a new proxy contract for each token ID, connected to the protocol's Manager. This Manager, controlled by the NFT, empowers the token ID holder with ownership rights.

Crucially, the Manager can integrate plugins—additional smart contracts—that are also upgradeable exclusively by the NFT owner. This ensures that when a new trusted version of the Manager or a plugin is released, the NFT owner can independently upgrade, accessing new features and security enhancements.

Thus, the Cruna Protocol guarantees that no unilateral contract upgrades occur. Only the NFT owner has the authority to initiate updates for the Manager and its plugins, balancing robust security with user autonomy and flexibility.

## What's Next for Cruna Vault?

We're continuously evolving and have exciting features in the pipeline:

### Distributor Vault

This specialized vault is all about automating asset distribution. Load it with assets, set a schedule, and let it do the rest, perfect for companies distributing tokens to investors or employees.

### Hardware protectors

We're introducing secure USB keys as an extra layer of security. These keys are tailored for Cruna Vaults, making them a simple yet powerful addition to your asset management toolkit.

### Privacy protected Vaults

A new family of Zero Knowledge based vaults will allow a high level of privacy.

## Experimental Features

### ERC-1155 support

In addition to ERC-721, Cruna Protocol may support ERC-1155 tokens in a near future. We are investigating the best way to do it and if there are reasonable use cases for it. For example, the plugin architecture could extend what an ERC-1155 token could do.

## In summary

Cruna Vault is more than just an NFT; it's a comprehensive solution for securing and managing your digital assets, today and in the future. Join us in embracing this new era of digital asset security.

## Development

Cruna is in beta stage, and to use it you must specify the version you want to install. Install it with, for example

```sh
npm install @cruna/protocol@1.0.0-beta.7 @openzeppelin/contracts erc6551
```
or similar commands using Yarn or Pnpm, and use in your Solidity smart contracts, for example, as

```
import {CrunaManagedNFTOwnable} from "@cruna/protocol/contracts/manager/CrunaManagedNFTOwnable.sol";

contract MySuperToken is CrunaManagedNFTOwnable {
   
    constructor(
    address registry_,
    address guardian_,
    address managerProxy_
  ) CrunaManagedOwnable("My Super Token", "MST", registry_, guardian_, managerProxy_) {}
}
```

If your goal is to build a plugin, look at the contracts in [contracts/mocks/plugin-example](./contracts/mocks/plugin-example) to start from.

## History

**1.0.0-rc.3**
- Plugins are now deployed by the NFT, not by the manager. This avoids issues when deploying plugins that supports IERC6551Account 
- Canonical addresses for CrunaRegistry, CrunaGuardian and ERC6551Registry are now constant and hardcoded
- Add more features in SignatureValidator to generalize common operations

**1.0.0-rc.2**
- Fix bug in CrunaManagedNFTBase#init

**1.0.0-rc.1**
- Add support for multi-sig and ERC4337 wallets as protectors. Since they cannot sign a valid typed_v4 signature, they must pre-approve the operation
- Add firstTokenId to the init function of a CrunaManagedNFT to allow the owner to set the first tokenId (essential to define cross/multi-chain strategies)

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
- Move events like ProtectorChange, SafeRecipientChange, etc. from the Manager to the Vault, because listening to events emitted by the vault is simpler than listening to the events emitted by all the managers

**1.0.0-beta.4**
- Renaming contracts to better distinguish them
- Add a function to allow a CrunaManaged NFT to upgrade the default implementation of the CrunaManager to a new version
- Simplify proxies
- Split ManagedERC721 in a basic contract, CrunaManagedBase, and two implementations based on Ownable and TimeControlled. The second is used by CrunaVaults, but the other can be chosen by less critical projects.
- Extend TimeControlled also in the Guardian, to guarantee the fairness of the trusted implementations 

**1.0.0-beta.3**
- Better interface organization
- Move contracts used only for testing to the mocks folder
- Add Time Lock to Guardian

**1.0.0-beta.2**
- Fix typo in CrunaRegistry function name
- Reorganize folders and files
- Add function to check if plugins needs to be reset on vault transfer

**1.0.0-beta.1**
- Improve the function `authorizePluginToTransfer` so that it disallows only temporarily a plugin to transfer the NFT 

**1.0.0-beta.0**
- Add views to manager to be able to see which plugins are active, disabled, etc.
- Add maxTokenId to ManagedERC721 to set a cap to the minting of tokens
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

## Test coverage

```
  44 passing

------------------------------------|----------|----------|----------|----------
File                                |  % Stmts | % Branch |  % Funcs |  % Lines 
------------------------------------|----------|----------|----------|----------
 interfaces/                        |      100 |      100 |      100 |      100 
  IERC6454.sol                      |      100 |      100 |      100 |      100 
  IERC6982.sol                      |      100 |      100 |      100 |      100 
 manager/                           |    98.25 |    68.38 |    98.18 |     98.4 
  Actor.sol                         |      100 |       60 |      100 |      100 
  CrunaManager.sol                  |    98.55 |     69.3 |      100 |    98.68 
  CrunaManagerBase.sol              |    93.33 |    66.67 |    85.71 |    94.12 
  CrunaManagerProxy.sol             |      100 |      100 |      100 |      100 
  ICrunaManager.sol                 |      100 |      100 |      100 |      100 
 plugins/                           |      100 |    83.33 |      100 |      100 
  CrunaPluginBase.sol               |      100 |    83.33 |      100 |      100 
  ICrunaPlugin.sol                  |      100 |      100 |      100 |      100 
 plugins/inheritance/               |      100 |    70.31 |      100 |     97.5 
  IInheritanceCrunaPlugin.sol       |      100 |      100 |      100 |      100 
  InheritanceCrunaPlugin.sol        |      100 |    70.31 |      100 |     97.5 
  InheritanceCrunaPluginProxy.sol   |      100 |      100 |      100 |      100 
 token/                             |    94.64 |    70.37 |    95.83 |    95.08 
  CrunaManagedNFTBase.sol           |    94.12 |    69.57 |    94.74 |    94.74 
  CrunaManagedNFTOwnable.sol        |      100 |       50 |      100 |      100 
  CrunaManagedNFTTimeControlled.sol |      100 |    83.33 |      100 |      100 
  ICrunaManagedNFT.sol              |      100 |      100 |      100 |      100 
  IVault.sol                        |      100 |      100 |      100 |      100 
 utils/                             |    94.55 |    68.52 |    96.55 |     94.2 
  CanonicalAddresses.sol            |      100 |      100 |      100 |      100 
  CrunaGuardian.sol                 |      100 |       50 |      100 |       75 
  CrunaRegistry.sol                 |      100 |      100 |      100 |      100 
  ERC6551AccountProxy.sol           |       90 |       75 |      100 |    90.91 
  FlexiTimelockController.sol       |      100 |       50 |      100 |      100 
  ICanonicalAddresses.sol           |      100 |      100 |      100 |      100 
  ICrunaGuardian.sol                |      100 |      100 |      100 |      100 
  ICrunaRegistry.sol                |      100 |      100 |      100 |      100 
  INamed.sol                        |      100 |      100 |      100 |      100 
  INamedAndVersioned.sol            |      100 |      100 |      100 |      100 
  ITokenLinkedContract.sol          |      100 |      100 |      100 |      100 
  IVersioned.sol                    |      100 |      100 |      100 |      100 
  SignatureValidator.sol            |      100 |       90 |      100 |      100 
  TokenLinkedContract.sol           |       80 |       50 |       80 |    88.89 
------------------------------------|----------|----------|----------|----------
All files                           |    97.46 |    69.69 |    97.78 |     97.1 
------------------------------------|----------|----------|----------|----------
```

## License

Copyright (C) 2023 Cruna

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You may have received a copy of the GNU General Public License
along with this program. If not,
see <https://www.gnu.org/licenses/gpl-3.0.en.html>.
