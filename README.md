**Cruna Vault Protocol README.md**

---

## Introduction
Welcome to the **Cruna Vault Protocol**: a groundbreaking advancement in digital asset security across blockchain platforms. Merging with ERC-6551 smart wallets, Cruna Vault introduces 'Protectors' and 'Sentinels', transforming the security landscape for digital assets.

---

## Overview
Cruna Vault is not merely an NFT; it's a sophisticated security mechanism. By integrating with ERC-6551 smart wallets, it addresses the existing security gaps in the ERC-6551 standard, providing a fortified layer of protection.

---

## CrunaFlexiVault
### Features
- **Smart Wallet Ownership**: Owns an ERC-6551 smart wallet, offering a fortified environment for digital assets.
- **Enhanced Security**: Elevates the security of standard ERC-6551 wallets, mitigating risks like phishing.

### Usage
- Primarily used to create and manage secure ERC-6551 smart wallets, it extends beyond both conventional NFT functionalities and standard ERC-6551 wallets.

---

## Protector System
### Key Concepts
- **Protector**: Ethereum addresses designated for additional security of the ERC-6551 smart wallet.
- **Flexible Management**: Dynamic control over protectors to bolster wallet security.

### Functionalities
- **Adding Protectors**: Enhances wallet security by allowing owners to assign protectors.
- **Transaction Approval**: Protectors validate high-stakes transactions, adding an extra security layer.

### Use Cases
- **Secured Asset Storage**: Safeguards assets in ERC-6551 smart wallets.
- **Protected High-Value Transactions**: Ensures secure asset transfers in ERC-6551 wallets.

---

## Safe Recipients in Cruna
### Key Concepts
- **Safe Recipient**: Trusted Ethereum addresses marked safe for transactions.
- **Dynamic Management**: Capability to adjust the list of safe recipients as needed.

### Functionalities
- **Designation of Safe Recipients**: Owners mark certain addresses as safe for transactions.
- **Protector's Authorization**: Protectors have a say in setting up safe recipients.

### Use Cases
- **Securing Transactions**: Ensures secure transfers to pre-approved addresses.
- **Enhanced Protector Oversight**: Protectors play a crucial role in managing safe recipients.

---

## Sentinels and Beneficiary: Proof of Life System with Quorum
### Key Concepts
- **Sentinels**: Trusted addresses managing NFTs during the owner's incapacity.
- **Quorum System**: A consensus mechanism among Sentinels for decision-making.

### Functionalities
- **Sentinel Management**: Owners appoint or remove Sentinels.
- **Inheritance Configuration**: Sets parameters for inheritance, including Quorum and Proof of Life duration.

### Use Cases
- **Estate and Asset Management**: Sentinels take charge of NFTs as per the owner's directives.
- **Collective Decision-Making**: Ensures balanced asset management through the Quorum system.

---

## Future Developments
- **Distributor Vault**: Streamlines scheduled asset distribution.
- **Inheritance Vault**: Enhances the applications in asset management and security.
- **Hardware Protectors**: Introduces USB keys for increased security.
- **Privacy Protected Vaults**: Offers a high level of privacy using Zero Knowledge proofs.

---

## History
- **Version 0.0.1**: Initial release with comprehensive test coverage.

---

## Test coverage

```
  12 passing (4s)

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
