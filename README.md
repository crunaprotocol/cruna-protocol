# Introducing Cruna Vault: The Next-Generation Security NFT

Cruna Vault is not just an NFT; it's a groundbreaking security tool designed to redefine the safety of digital assets. Created for seamless integration with ERC-6551 smart wallets, it brings two innovative features to the forefront: Protectors and Sentinels.

## Key Components

### Cruna Vault, Non-Fungible Tokens (NFTs) and Protectors

The Cruna Vault represents the core of the Cruna Core Protocol. It is an NFT that a user must own to manage the vault, playing a crucial role in the structure and functionality of the protocol.

The owning token within this structure functions as a standard NFT, providing a bridge between the owner and the application(s) associated with the vault. To enhance security, the protocol incorporates ProtectedERC721 contracts—NFTs capable of adding special wallets, termed 'Protectors'.

The Protectors play a critical role in enhancing the security of the protocol. In the Cruna Vault, the NFT owner can appoint one or more Protectors. While Protectors lack the authority to initiate NFT transfers independently, they must pre-approve any transfer requests initiated by the owner, signing the request. This two-tier authentication mechanism significantly reduces the risk of unauthorized NFT transfers, even in cases where the owner's account may be compromised.

To add flexibility to the system, the vault owner can set allow-listed recipient that can receive assets without requiring the pre-approval from a protector. This is particularly useful in a company environment, where some wallets receiving assets do not need approval. This feature must be used carefully, because can make the Protectors useless.

Once the owner designates the first Protector, the second Protector needs the pre-approval of the first protector to be set up. For similar reasons, a Protector cannot be removed unilaterally by the owner but must provide a valid signature.

It is advisable to assign multiple Protectors to maintain access to the vault even if one Protector becomes inaccessible. Reasonably, if there is a need for more than two protectors, it may make sense to transfer the ownership of the vault to a multisig wallet.

#### Asset Recovery and Inheritance Management

The Cruna Vault provides a mechanism for asset recovery in case the owner loses access or passes away. The owner can designate sentinels and set a recovery quorum and expiration timeframe.

Before the expiry, the owner has to trigger a Proof-of-Life event to indicate they still retain access. If the event isn't triggered, a sentinel can initiate the recovery process and suggest a beneficiary wallet.

Other sentinels can confirm the transfer or reject it. If rejected, they can suggest an alternate recipient. The protocol is designed to prevent blocking of the process by hostile sentinels.

This inheritance management system enables orderly transfer of assets to successors in case of incapacity or demise of the vault owner. It provides individuals and entities a way to ensure business continuity and asset inheritance in a secure manner.

By integrating Protectors and Sentinels, Cruna Vault offers an unmatched level of security and peace of mind. It ensures that your digital assets are not only protected against external threats but also have a resilient plan for unforeseen circumstances. Cruna Vault is more than an NFT; it's a comprehensive digital asset protection system, safeguarding your investments today and into the future.

### Use Cases

- Consolidate all assets of a collection into a single Vault, allowing a seamless transfer of ownership without needing to move each asset individually. This offers significant improvements in security and user experience.

- Create asset bundles and list them for sale as a single NFT on popular marketplaces like OpenSea.

- Deposit vested assets into a Flexi Vault for scheduled distribution to investors, team members, etc. Note that for this to work, the asset must be capable of managing the vesting schedule. In a future version of the Cruna Core Protocol, a Flexi Distributor will be introduced to handle the vesting of any assets.

- Create a Flexi Vault for a DAO, allowing the DAO to manage its assets collectively.

- Use a Cruna Vault to give assets to siblings. For example, a user can set a vault for his kids and when they are adult can just transfer the Vault to them, instead of transferring the assets one by one.

- A company can put their reserves in a vault, "owned" by the CEO, with an inheritance process allowing the board directors to recover the assets in case the CEO becomes unavailable for any reason.

### Future developments

As the Cruna Core Protocol continues to evolve, many additions are currently in the pipeline: the Distributor Vault. Each of these vaults caters to specific needs, expanding the applications of the Cruna Core Protocol in the realms of asset management and security.

#### Distributor Vault

The Distributor Vault is a specialized vault designed to streamline the process of scheduled asset distribution. An entity can pre-load this vault with assets, which are then automatically distributed to the designated beneficiaries according to a predetermined schedule.

This functionality can be advantageous in numerous scenarios. For instance, a company wishing to distribute its governance tokens (ERC20) can purchase a Distributor Vault, fill it with the appropriate tokens, and set a vesting schedule. Once the NFT ownership of the Distributor Vault is given to an investor, the company no longer needs to actively manage token distribution. The tokens will be vested and delivered automatically as per the set schedule, providing the investor with an assurance of receiving their assets in a timely manner. This system is not only beneficial for investors, but it can also be employed for the scheduled distribution of tokens to employees, advisors, and other stakeholders.

#### Hardware protectors

Within the framework of the Cruna Protocol, we're introducing specialized USB keys designed to further bolster the security and functionality of our platform. These USB devices implement a streamlined wallet architecture singularly focused on executing typed V4 signatures. By narrowing down the wallet's capabilities to this specific type of signature, we ensure a higher level of protection against potential threats. When integrated with Cruna's unique Vault system, these USB keys serve as an inexpensive and robust protectors, amplifying the assurance our users have in the safety of their consolidated assets. This innovation reflects Cruna Protocol's commitment to staying at the forefront of cryptographic security, providing our users with tools that are both powerful and user-friendly.

#### Privacy protected Vaults

A new family of Zero Knowledge based vaults will allow a high level of privacy.

## History

**0.0.1**

- First version

## Test coverage

```
  12 passing (5s)

-----------------------------|----------|----------|----------|----------|----------------|
File                         |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
-----------------------------|----------|----------|----------|----------|----------------|
 contracts/                  |       60 |       40 |    66.67 |    71.43 |                |
  CrunaFlexiVault.sol        |       60 |       40 |    66.67 |    71.43 |          50,55 |
 contracts/factory/          |    57.14 |     37.5 |    81.82 |    58.18 |                |
  IVaultFactory.sol          |      100 |      100 |      100 |      100 |                |
  VaultFactory.sol           |    57.14 |     37.5 |    81.82 |    58.18 |... 126,130,143 |
 contracts/manager/          |    56.48 |    32.65 |    59.52 |     54.4 |                |
  Actor.sol                  |    78.13 |    44.44 |    81.82 |    72.97 |... 67,68,69,72 |
  Guardian.sol               |      100 |      100 |        0 |      100 |                |
  IActor.sol                 |      100 |      100 |      100 |      100 |                |
  IManager.sol               |      100 |      100 |      100 |      100 |                |
  Manager.sol                |    47.37 |       30 |    51.72 |    46.59 |... 356,357,360 |
  ManagerProxy.sol           |      100 |      100 |      100 |      100 |                |
 contracts/protected/        |    67.86 |    33.33 |    63.64 |    66.67 |                |
  IERC6454.sol               |      100 |      100 |      100 |      100 |                |
  IProtected.sol             |      100 |      100 |      100 |      100 |                |
  ProtectedNFT.sol           |    67.86 |    33.33 |    63.64 |    66.67 |... 131,132,148 |
 contracts/utils/            |    92.31 |    66.67 |    66.67 |    81.82 |                |
  SignatureValidator.sol     |      100 |     87.5 |      100 |     87.5 |             31 |
  UUPSUpgradableTemplate.sol |      100 |       25 |       50 |      100 |                |
  Versioned.sol              |        0 |      100 |        0 |        0 |              9 |
-----------------------------|----------|----------|----------|----------|----------------|
All files                    |    60.71 |    36.19 |    64.47 |    59.07 |                |
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
