# Cruna Protocol: A Technical Overview

## Abstract

The Cruna Protocol represents a novel approach to enhancing the security, inheritability, and expandability of Non-Fungible Tokens (NFTs). By leveraging a unique contract architecture, the protocol introduces mechanisms for setting protectors, managing safe recipients, and integrating expandable features through plugins. This document provides a technical overview of the protocol's functionalities, focusing on the protocol's innovative use of smart contracts and plugins.

## Introduction
In the burgeoning field of digital assets, the need for advanced security and flexible management of NFTs has become increasingly apparent. The Cruna Protocol addresses these needs through a sophisticated smart contract ecosystem designed to protect, inherit, and expand NFT functionalities.

## Cruna Protocol Architecture

At the foundation of the Cruna Protocol lies a robust architecture designed to ensure security, flexibility, and interoperability of NFTs across the blockchain ecosystem. Central to this architecture are the ERC7656Registry, CrunaGuardian, CrunaManager, and CrunaManagerProxy contracts, each playing a pivotal role in the ecosystem.

### ERC7656Registry and CrunaGuardian: The Backbone of Cruna Protocol
The protocol initiates with the deployment of two key contracts: the ERC7656Registry and the CrunaGuardian.

- **ERC7656Registry**: This contract functions as a registry, creating token-linked contracts and predicting/returning their addresses. It serves as the cornerstone for the dynamic interaction between NFTs and their associated functionalities within the Cruna ecosystem.
- **CrunaGuardian**: Operated as a time-controlled contract and managed by a Decentralized Autonomous Organization (DAO), the CrunaGuardian's primary role is to set and retrieve secure implementations for managers and plugins. This governance structure ensures that the protocol remains secure and adaptable over time.

Both the ERC7656Registry and the CrunaGuardian contracts are deployed using Nick's Factory, enabling their addresses to be hardcoded within referring contracts. This approach guarantees address consistency across different deployments, ensuring that these foundational elements maintain stability and reliability within the protocol's architecture.

### Deployment of CrunaManager and CrunaManagerProxy
Following the establishment of the ERC7656Registry and CrunaGuardian, the deployment of the CrunaManager and CrunaManagerProxy contracts is executed. These contracts are essential for the management and operational functionality of the NFTs within the protocol.

- **CrunaManager**: Acts as the central hub for each NFT, facilitating the setting of protectors, management of safe recipients, and integration of plugins. This contract embodies the core principles of security and expandability inherent to the Cruna Protocol.
- **CrunaManagerProxy**: Utilized for the efficient deployment of CrunaManager instances, this proxy contract ensures a cost-effective and scalable framework for the dynamic creation of NFT-specific management contracts.

Utilizing Nick's Factory for their deployment, the CrunaManager and CrunaManagerProxy contracts are designed to have consistent addresses across any EVM-compatible blockchain. This deployment strategy enhances the protocol's interoperability and facilitates a seamless integration within the broader blockchain ecosystem.

### Extensibility and Development
With the deployment of the core architecture, the Cruna Protocol is primed for extension and adoption by developers. By extending the CrunaProtectedNFT contract, developers can create projects that leverage the advanced security and functionality features of the protocol. Additionally, the protocol provides sample templates for developers interested in building plugins, further enriching the ecosystem with innovative features and applications.

This foundational architecture not only supports the current functionalities of the Cruna Protocol but also lays the groundwork for future developments and enhancements. Through its carefully designed components and governance structures, the Cruna Protocol is poised to redefine the landscape of NFT security, inheritability, and expandability.

## Manager Deployment Upon Token Minting
One of the innovative features of the Cruna Protocol is the automated deployment of a unique manager for each NFT at the time of minting. This process is central to ensuring that each NFT within the Cruna ecosystem is equipped with its own secure and customizable management capabilities.

### Minting Process and Manager Deployment
The minting of a new token ID through the **CrunaProtectedNFT** contract initiates a call to the **ERC7656Registry**, which in turn deploys an optimized proxy for the **CrunaManager**. This proxy uses the **CrunaManagerProxy** as its implementation, adhering to a variation of the **ERC-6551 Registry** standards for deploying token-linked contracts.

The key to this process is the efficiency and cost-effectiveness of the deployment. The bytecode deployed by the **ERC7656Registry** for each manager is only 173 bytes long, significantly reducing the gas cost associated with the creation of these management contracts. This efficiency is critical in maintaining the scalability of the Cruna Protocol, allowing for the widespread minting and management of NFTs without prohibitive costs.

### Binding and Management of the Token ID
Once deployed, the manager is intrinsically bound to its corresponding NFT, creating a permanent link that ensures the manager can only be operated and controlled by the owner of that specific NFT. This binding guarantees that each NFT has a dedicated management system, enhancing the security and integrity of the asset's management throughout its lifecycle.

### Plugin Deployment and Management
The deployment and integration of plugins within the Cruna Protocol are designed to enhance the functionality and customization options available for each NFT. This process is carefully tailored based on the nature and purpose of the plugin:

- **General Plugins**: For plugins that extend the NFT's functionalities without acting as wallets, the **CrunaProtectedNFT** utilizes the **ERC7656Registry** for deployment. This approach ensures that these plugins are seamlessly integrated into the NFT's ecosystem, providing a wide range of additional capabilities and services directly linked to the NFT.

- **Token-Bound Account Plugins**: In instances where plugins serve as token-bound accounts, essentially allowing the NFT to operate as a wallet, the deployment process leverages the canonical **ERC-6551 Registry**.
 
This dual-pathway for plugin deployment underscores the protocol's flexibility and its ability to accommodate a broad spectrum of plugin functionalities, from enhancing the NFT's inherent features to enabling it to act as a fully operational wallet. The use of both the ERC7656Registry and the canonical ERC-6551 Registry for different types of plugins exemplifies the protocol's adaptability and commitment to providing comprehensive management solutions for NFT owners and developers.

# API documentation

- Erc
  - [ERC6551AccountProxy](./erc/ERC6551AccountProxy.md)
  - [ERC7656Contract](./erc/ERC7656Contract.md)
  - [ERC7656Registry](./erc/ERC7656Registry.md)
  - [IERC6454](./erc/IERC6454.md)
  - [IERC6982](./erc/IERC6982.md)
  - [IERC7656Contract](./erc/IERC7656Contract.md)
  - [IERC7656Registry](./erc/IERC7656Registry.md)
- Guardian
  - [CrunaGuardian](./guardian/CrunaGuardian.md)
  - [ICrunaGuardian](./guardian/ICrunaGuardian.md)
- Libs
  - [Canonical](./libs/Canonical.md)
  - [ExcessivelySafeCall](./libs/ExcessivelySafeCall.md)
  - [ManagerConstants](./libs/ManagerConstants.md)
  - [TrustedLib](./libs/TrustedLib.md)
- Manager
  - [Actor](./manager/Actor.md)
  - [CrunaManager](./manager/CrunaManager.md)
  - [CrunaManagerBase](./manager/CrunaManagerBase.md)
  - [CrunaManagerProxy](./manager/CrunaManagerProxy.md)
  - [ICrunaManager](./manager/ICrunaManager.md)
- Services
  - [CrunaManagedService](./services/CrunaManagedService.md)
  - [CrunaService](./services/CrunaService.md)
  - [ICrunaManagedService](./services/ICrunaManagedService.md)
  - [ICrunaService](./services/ICrunaService.md)
- Services/inheritance
  - [IInheritanceCrunaPlugin](./services/inheritance/IInheritanceCrunaPlugin.md)
  - [InheritanceCrunaPlugin](./services/inheritance/InheritanceCrunaPlugin.md)
  - [InheritanceCrunaPluginProxy](./services/inheritance/InheritanceCrunaPluginProxy.md)
- Token
  - [CrunaProtectedNFT](./token/CrunaProtectedNFT.md)
  - [CrunaProtectedNFTOwnable](./token/CrunaProtectedNFTOwnable.md)
  - [CrunaProtectedNFTTimeControlled](./token/CrunaProtectedNFTTimeControlled.md)
  - [ICrunaProtectedNFT](./token/ICrunaProtectedNFT.md)
  - [IManagedNFT](./token/IManagedNFT.md)
- Utils
  - [CommonBase](./utils/CommonBase.md)
  - [Deployed](./utils/Deployed.md)
  - [ICommonBase](./utils/ICommonBase.md)
  - [INamed](./utils/INamed.md)
  - [INamedAndVersioned](./utils/INamedAndVersioned.md)
  - [ISignatureValidator](./utils/ISignatureValidator.md)
  - [IVersioned](./utils/IVersioned.md)
  - [SignatureValidator](./utils/SignatureValidator.md)


The documentation is automatically generated using [solidity-docgen](https://github.com/OpenZeppelin/solidity-docgen)

(c) 2024+ Cruna
