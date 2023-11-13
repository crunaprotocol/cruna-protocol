// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

import {ProtectedNFT, Strings} from "./protected/ProtectedNFT.sol";

//import "hardhat/console.sol";

// reference implementation of a Cruna Vault
contract CrunaFlexiVault is ProtectedNFT {
  using Strings for uint256;

  error NotTheFactory();
  error ZeroAddress();

  address public factoryAddress;

  modifier onlyFactory() {
    if (factoryAddress == address(0) || _msgSender() != factoryAddress) revert NotTheFactory();
    _;
  }

  constructor(
    // Notice that the registry address is fixed and could be hardcoded
    // but if so, we cannot properly test the contract. So, we will pass it
    // as a parameter in the deployment scripts.
    address registry_,
    address guardian_,
    address signatureValidator_,
    address manager_,
    address managerProxy_
  ) ProtectedNFT("Cruna Flexi Vault V1", "CRUNA1", registry_, guardian_, signatureValidator_, manager_, managerProxy_) {}

  // set factory to 0x0 to disable a factory
  function setFactory(address factory) external virtual onlyOwner {
    if (factory == address(0)) revert ZeroAddress();
    factoryAddress = factory;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return "https://meta.cruna.cc/flexy-vault/v1/";
  }

  function contractURI() public view virtual returns (string memory) {
    return "https://meta.cruna.cc/flexy-vault/v1/info";
  }

  function safeMint(address to) public virtual onlyFactory {
    _mintAndInit(to);
  }
}
