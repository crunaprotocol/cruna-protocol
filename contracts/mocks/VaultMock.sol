// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {CrunaManaged, Strings} from "../token/CrunaManaged.sol";

//import "hardhat/console.sol";

// This is actually the real Cruna Flexi Vault contract.
// We put it in mocks because it should not be used loading the package.

// @dev This contract is a simple example of a protected NFT.
contract VaultMock is CrunaManaged {

  using Strings for uint256;

  error NotTheFactory();

  address public factory;

  // @dev This modifier will only allow the factory to call the function.
  //   The factory is the contract that manages the sale of the tokens.
  modifier onlyFactory() {
    if (factory == address(0) || _msgSender() != factory) revert NotTheFactory();
    _;
  }

  // @dev This constructor will initialize the contract with the necessary parameters
  //   The contracts of whom we pass the addresses in the construction, will be deployed
  //   using Nick's factory, so we may in theory hardcode them in the code. However,
  //   if so, we will not be able to test the contract.
  // @param owner The address of the owner.
  constructor(address owner) CrunaManaged("Cruna Vaults", "CRUNA1", owner) {}

  // @dev Set factory to 0x0 to disable a factory.
  // @notice This is the only function that can be called by the owner.
  //   It does not introduce centralization, because it is related with
  //   the factory that sells the tokens, not the NFT itself.
  // @param factory The address of the factory.
  function setFactory(address factory_) external virtual onlyOwner {
    if (factory_ == address(0)) revert ZeroAddress();
    factory = factory_;
  }

  // @dev This function will return the base URI of the contract
  function _baseURI() internal view virtual override returns (string memory) {
    return string(abi.encodePacked("https://meta.cruna.cc/vault/v1/", block.chainid.toString(), "/"));
  }

  // @dev This function will return the contract URI of the contract
  function contractURI() public view virtual returns (string memory) {
    return string(abi.encodePacked("https://meta.cruna.cc/vault/v1/", block.chainid.toString(), "/info"));
  }

  // @dev This function will mint a new token
  // @param to The address of the recipient
  function safeMintAndActivate(address to, bool alsoInit, uint256 amount) public virtual onlyFactory {
    _mintAndActivate(to, alsoInit, amount);
  }
}
