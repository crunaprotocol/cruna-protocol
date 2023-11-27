// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

import {ProtectedNFT, Strings} from "./protected/ProtectedNFT.sol";

//import "hardhat/console.sol";

// @dev This contract is a simple example of a protected NFT.
contract CrunaFlexiVault is ProtectedNFT {
  using Strings for uint256;

  error NotTheFactory();

  address public factoryAddress;

  // @dev This modifier will only allow the factory to call the function.
  //   The factory is the contract that manages the sale of the tokens.
  modifier onlyFactory() {
    if (factoryAddress == address(0) || _msgSender() != factoryAddress) revert NotTheFactory();
    _;
  }

  // @dev This constructor will initialize the contract with the necessary parameters
  //   The contracts of whom we pass the addresses in the construction, will be deployed
  //   using Nick's factory, so we may in theory hardcode them in the code. However,
  //   if so, we will not be able to test the contract.
  // @param registry_ The address of the registry contract.
  // @param guardian_ The address of the Manager.sol guardian.
  // @param signatureValidator_ The address of the signature validator.
  // @param managerProxy_ The address of the managers proxy.
  constructor(
    address registry_,
    address guardian_,
    address signatureValidator_,
    address managerProxy_
  ) ProtectedNFT("Cruna Flexi Vault V1", "CRUNA1", registry_, guardian_, signatureValidator_, managerProxy_) {}

  // @dev Set factory to 0x0 to disable a factory.
  // @notice This is the only function that can be called by the owner.
  //   It does not introduce centralization, because it is related with
  //   the factory that sells the tokens, not the NFT itself.
  // @param factory The address of the factory.
  function setFactory(address factory) external virtual onlyOwner {
    if (factory == address(0)) revert ZeroAddress();
    factoryAddress = factory;
  }

  // @dev This function will return the base URI of the contract
  function _baseURI() internal view virtual override returns (string memory) {
    return "https://meta.cruna.cc/flexy-vault/v1/";
  }

  // @dev This function will return the contract URI of the contract
  function contractURI() public view virtual returns (string memory) {
    return "https://meta.cruna.cc/flexy-vault/v1/info";
  }

  // @dev This function will mint a new token
  // @param to The address of the recipient
  function safeMint(address to) public virtual onlyFactory {
    _mintAndInit(to);
  }
}
