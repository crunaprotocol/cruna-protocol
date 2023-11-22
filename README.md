# Overview of Cruna and Protectors

## CrunaFlexiVault

**CrunaFlexiVault** is a key component of the Cruna ecosystem, designed to enhance the capabilities of ERC-721 NFTs by integrating them with Ethereum's ERC-6551 standard. This integration allows each NFT to operate as its own smart contract, thus providing advanced functionalities.

### Features:

- **Smart Contract Enabled NFTs**: Each NFT in the CrunaFlexiVault acts as an independent smart contract, capable of executing complex operations.
- **Enhanced Security and Functionality**: The integration with ERC-6551 standard allows for additional layers of security and more dynamic interactions for NFTs.

### Usage:

The CrunaFlexiVault is used for creating and managing NFTs with advanced capabilities. These NFTs can interact with other contracts and perform operations beyond the scope of traditional NFTs.

## Protector System

The **Protector System** in Cruna is a security feature that allows NFT owners to assign protectors to their NFTs, further securing their digital assets.

### Key Concepts:

- **Protector**: A protector is an Ethereum address (e.g., another user) designated to provide an additional layer of security and control over the NFT.
- **Flexible Management**: Owners can add or remove protectors, providing flexibility in managing their NFTs.

### Functionalities:

- **Adding Protectors**: NFT owners can designate other addresses as protectors, enhancing the security of their NFTs.
- **Approval Process**: Certain operations, like transferring the NFT, may require approval or signatures from assigned protectors.
- **Protector Management**: Owners can manage protectors, adding multiple protectors and even allowing protectors to add or remove other protectors.

### Use Cases:

- **Secured Transfers**: Transferring an NFT can be made secure with protector approval, preventing unauthorized transfers.
- **Multi-Signature Operations**: Protectors can enable multi-signature operations for high-value NFTs, adding an extra layer of consensus before executing critical actions.

### Example Workflow:

#### Vault Purchase and Setup:

- An NFT owner purchases a vault from the CrunaFlexiVault.
- They set up their NFT within this vault, turning it into a smart contract capable NFT.

#### Assigning Protectors:

- The owner assigns one or more protectors to their NFT for additional security.

#### Performing Operations:

- For operations like transfers, the owner initiates the action.
- If required, protectors provide their approval or signature to complete the transaction.

## Conclusion

The CrunaFlexiVault and Protector system offer a sophisticated approach to NFT security and functionality. By leveraging smart contract capabilities and a robust protector management system, Cruna enhances the utility and security of NFTs in the Ethereum ecosystem.

---
## Safe Recipients in Cruna

The "Safe Recipients" feature in Cruna is a crucial security mechanism that allows NFT owners to designate specific Ethereum addresses as trusted entities for transactions. This system plays a vital role in enhancing the control and safety of NFT transfers within the Cruna ecosystem.

### Key Concepts:

- **Safe Recipient**: A designated Ethereum address recognized as a trusted recipient for an NFT. This address is considered secure for transactions and interactions with the NFT.
- **Dynamic Management**: NFT owners have the ability to dynamically manage their list of safe recipients, adding or removing addresses as needed.

### Functionalities:

- **Designation of Safe Recipients**: Owners can designate certain addresses as safe recipients, ensuring transactions are secure and trusted.
- **Protector's Authorization**: In cases where protectors are assigned, they can authorize or influence the designation of safe recipients.
- **Flexibility in Management**: The system allows for the easy addition or removal of safe recipients, adapting to the owner's changing requirements.

### Use Cases:

- **Securing Transactions**: The feature ensures that NFTs are only transferred or interacted with by pre-approved, trustworthy addresses.
- **Enhanced Oversight by Protectors**: Protectors play a critical role in overseeing and authorizing the setting of safe recipients, particularly important for high-value or sensitive NFTs.

### Example Workflow:

#### Setting Up Safe Recipients:

- An NFT owner, like `bob`, designates trusted addresses such as `alice` and `fred` as safe recipients.
- Protectors, if any, can approve or suggest changes to these designations.

#### Managing Recipients:

- Owners can update the list of safe recipients, adding new ones or removing existing ones, with or without the involvement of protectors.

## Conclusion

The Safe Recipients system in Cruna offers a robust framework for ensuring that NFT transactions occur within a trusted and secure network. By providing NFT owners with the tools to manage who can receive their assets, Cruna significantly enhances the safety and control over digital asset transactions.

---
## Sentinels and Beneficiary in Cruna: Proof of Life System with Quorum

In Cruna's ecosystem, the "Sentinels" and "Beneficiary" features form the core of the Proof of Life system. This system is designed for the secure management of NFTs, especially in continuity-critical situations. The Quorum system among Sentinels, which activates after the Proof of Life period expires, is key to ensuring collective decision-making in these scenarios.

### Key Concepts:

- **Sentinels**: Trusted Ethereum addresses, such as estate executors, lawyers, or family members, designated to manage NFTs when the owner is incapacitated or deceased.
- **Quorum System**: A requirement for Sentinels to reach a consensus on decisions, particularly regarding the transfer of assets, thus ensuring balanced and secure management.

### Functionalities:

- **Sentinel Designation and Management**: Owners can appoint or remove Sentinels using the `setSentinel` function, with updates signified by `SentinelUpdated` events.
- **Inheritance Configuration**: The `configureInheritance` function sets up the inheritance parameters, including the Quorum and the Proof of Life duration.
- **Proof of Life Maintenance**: Owners can reset the Proof of Life timer via the `proofOfLife` function, impacting the Quorum system's activation.

### Use Cases:

- **Estate and Asset Management**: In the event of an owner's death or incapacity, Sentinels ensure that NFTs are managed or transferred according to the owner's wishes.
- **Collective Decision-Making**: The Quorum system mandates that Sentinels make decisions collectively, fostering balanced and fair management of assets.

### Example Workflow:

#### Configuring Sentinels and Quorum:

- An NFT owner assigns trusted individuals as Sentinels and configures the Quorum settings for collective decision-making.

#### Engaging in Proof of Life:

- The owner periodically updates their Proof of Life status, influencing the activation of the Quorum system among Sentinels.

#### Sentinel-Led Asset Transfer:

- Upon the owner's incapacity or death, Sentinels collectively decide on asset transfers, ensuring decisions are made per the owner's established guidelines.

## Conclusion

The Proof of Life system with Quorum, encompassing Sentinels and Beneficiary features in Cruna, offers a sophisticated approach to managing digital assets in sensitive situations. This system guarantees that NFTs are protected and transferred based on collective decisions, aligning with the original owner's intent and providing a robust framework for estate and asset management.

---
### Future developments

As the Cruna Core Protocol continues to evolve, many additions are currently in the pipeline: the Distributor Vault and the Inheritance Vault. Each of these vaults caters to specific needs, expanding the applications of the Cruna Core Protocol in the realms of asset management and security.

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
  12 passing (3s)

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
