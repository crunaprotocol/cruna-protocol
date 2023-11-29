# Cruna Vault: The Future of Secure Digital Asset Management

Welcome to Cruna Vault, a groundbreaking innovation in the world of NFTs (Non-Fungible Tokens). Unlike ordinary NFTs, Cruna Vault is a powerful tool designed to enhance the safety and management of your digital assets, perfect for pairing with [ERC-6551](https://eips.ethereum.org/EIPS/eip-6551) smart wallets.

## Cruna Vault + ERC-6551: A Game-Changer in Asset Security

ERC-6551 defines a system which assigns EVM-compatible accounts to all non-fungible tokens. These token bound accounts allow NFTs to own assets and interact with applications, without requiring changes to existing smart contracts or infrastructure.

While the ERC-6551 standard is a significant step forward in the evolution of NFTs, it lacks a critical component: security. The standard does not specify any security requirements for the NFT to whom the account is bound. This omission leaves the NFT vulnerable to unauthorized access and misuse, undermining the security of the entire system.

Cruna Vault is specially designed to work with ERC-6551 wallets, a new way for NFTs to manage digital assets seamlessly.

### Meet the Protectors

Protectors are like personal guardians for your NFT. As an NFT owner, you can appoint one or more Protectors who must approve any transfer or change. This dual-level security means even if your account is compromised, your NFT stays safe. For added convenience in specific scenarios, like in a company setting, you can set up special rules where certain transfers don't need Protector approval.

Once you set up your first Protector, adding or removing others requires approval too, ensuring no single person can make unilateral changes. This setup is ideal for those who value robust security in managing their digital assets.

_It is advisable to assign multiple Protectors to maintain access to the vault even if one Protector becomes inaccessible. Reasonably, if there is a need for more than two Protectors, it may make sense to transfer the ownership of the vault to a multisig wallet._

### Sentinels and Asset Recovery

Imagine a system that safeguards your assets even if you lose access or in case of unforeseen life events. That's what Sentinels do in Cruna Vault. They work on a Proof-of-Life system – you periodically signal that you're still in control. If you can't, Sentinels can start a process to pass your assets to a chosen Beneficiary.

This feature is not just about security; it's about peace of mind and ensuring your digital legacy is preserved and passed on as intended.

## Cruna Vault Plugin Architecture

The Cruna Protocol introduces a flexible Plugin Architecture with every Cruna Vault minted. Alongside the Vault, a Manager contract owned by the Vault is deployed, acting as the central hub for managing various functionalities.

### Manager's Role
The Manager plays a key role in overseeing crucial aspects of the Vault:

* Protectors and Safe Recipients: It handles the appointment and management of Protectors and Safe Recipients, ensuring robust security mechanisms.
* Plugin Management: The Manager is also in charge of managing the Vault’s plugins. For instance, functionalities like Sentinels and Beneficiaries are handled by the InheritanceManager, a specialized plugin within the system.
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

## What's Next for Cruna Vault?

We're continuously evolving and have exciting features in the pipeline:

### Distributor Vault

This specialized vault is all about automating asset distribution. Load it with assets, set a schedule, and let it do the rest, perfect for companies distributing tokens to investors or employees.

### Hardware protectors

We're introducing secure USB keys as an extra layer of security. These keys are tailored for Cruna Vaults, making them a simple yet powerful addition to your asset management toolkit.

### Privacy protected Vaults

A new family of Zero Knowledge based vaults will allow a high level of privacy.

## In summary

Cruna Vault is more than just an NFT; it's a comprehensive solution for securing and managing your digital assets, today and in the future. Join us in embracing this new era of digital asset security.

## History

**0.0.1**

- First version

## Test coverage

```
  17 passing (5s)

-----------------------------|----------|----------|----------|----------|----------------|
File                         |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
-----------------------------|----------|----------|----------|----------|----------------|
 contracts/                  |       60 |       40 |    66.67 |    71.43 |                |
  CrunaFlexiVault.sol        |       60 |       40 |    66.67 |    71.43 |          50,55 |
 contracts/factory/          |      100 |    60.42 |      100 |    98.18 |                |
  IVaultFactory.sol          |      100 |      100 |      100 |      100 |                |
  VaultFactory.sol           |      100 |    60.42 |      100 |    98.18 |            113 |
 contracts/interfaces/       |      100 |      100 |      100 |      100 |                |
  IERC6454.sol               |      100 |      100 |      100 |      100 |                |
  IERC6982.sol               |      100 |      100 |      100 |      100 |                |
  IProtected.sol             |      100 |      100 |      100 |      100 |                |
 contracts/manager/          |    92.22 |    59.72 |    86.49 |    93.27 |                |
  Actor.sol                  |    95.24 |    58.33 |       90 |    96.15 |             56 |
  Guardian.sol               |      100 |       50 |      100 |    83.33 |             19 |
  IManager.sol               |      100 |      100 |      100 |      100 |                |
  Manager.sol                |    91.07 |    61.11 |    78.95 |    92.19 |... 125,144,175 |
  ManagerBase.sol            |    88.89 |       50 |      100 |      100 |                |
  ManagerProxy.sol           |      100 |      100 |      100 |      100 |                |
 contracts/plugins/          |    97.06 |    56.82 |    90.91 |       94 |                |
  IInheritanceManager.sol    |      100 |      100 |      100 |      100 |                |
  IPlugin.sol                |      100 |      100 |      100 |      100 |                |
  InheritanceManager.sol     |    97.06 |    56.82 |    90.91 |       94 |     79,147,173 |
 contracts/protected/        |    86.21 |    42.86 |    76.92 |    89.74 |                |
  ProtectedNFT.sol           |    86.21 |    42.86 |    76.92 |    89.74 | 78,137,162,171 |
 contracts/utils/            |       75 |       25 |       60 |       75 |                |
  SignatureValidator.sol     |      100 |      100 |      100 |      100 |                |
  UUPSUpgradableTemplate.sol |      100 |       25 |       50 |      100 |                |
  Versioned.sol              |        0 |      100 |        0 |        0 |              9 |
-----------------------------|----------|----------|----------|----------|----------------|
All files                    |    92.65 |    54.55 |    84.34 |    93.05 |                |
-----------------------------|----------|----------|----------|----------|----------------|
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
