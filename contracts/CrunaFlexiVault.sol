// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

import {Protected, Strings} from "./protected/Protected.sol";

//import "hardhat/console.sol";

// reference implementation of a Cruna Vault
contract CrunaFlexiVault is Protected {
  using Strings for uint256;

  error NotTheFactory();
  error ZeroAddress();

  address public factoryAddress;

  modifier onlyFactory() {
    if (factoryAddress == address(0) || _msgSender() != factoryAddress) revert NotTheFactory();
    _;
  }

  constructor(
    address registry_,
    address guardian_,
    address signatureValidator_,
    address manager_,
    address managerProxy_
  ) Protected("Cruna Flexi Vault V1", "CRUNA1", registry_, guardian_, signatureValidator_, manager_, managerProxy_) {}

  // set factory to 0x0 to disable a factory
  function setFactory(address factory) external virtual onlyOwner {
    if (factory == address(0)) revert ZeroAddress();
    factoryAddress = factory;
  }

  function version() external pure virtual returns (string memory) {
    return "1.0.0";
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
