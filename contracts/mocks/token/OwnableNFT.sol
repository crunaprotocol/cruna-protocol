// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CrunaProtectedNFTOwnable} from "../../token/CrunaProtectedNFTOwnable.sol";

// import "hardhat/console.sol";

// This is actually the real Cruna Flexi Vault contract.
// We put it in mocks because it should not be used loading the package.

// @notice This contract is a simple example of a protected NFT.
contract OwnableNFT is CrunaProtectedNFTOwnable {
  using Strings for uint256;

  error NotTheFactory();

  address public factory;

  // @notice This modifier will only allow the factory to call the function.
  //   The factory is the contract that manages the sale of the tokens.
  modifier onlyFactory() {
    if (factory == address(0) || _msgSender() != factory) revert NotTheFactory();
    _;
  }

  // @notice This constructor will initialize the contract with the necessary parameters
  //   The contracts of whom we pass the addresses in the construction, will be deployed
  //   using Nick's factory, so we may in theory hardcode them in the code. However,
  //   if so, we will not be able to test the contract.
  // @param owner The address of the owner.
  constructor(address owner_) CrunaProtectedNFTOwnable("Cruna Vaults", "CRUNA1", owner_) {}

  // @notice Set factory to 0x0 to disable a factory.
  // @notice This is the only function that can be called by the owner.
  //   It does not introduce centralization, because it is related with
  //   the factory that sells the tokens, not the NFT itself.
  // @param factory The address of the factory.
  function setFactory(address factory_) external virtual {
    _canManage(true);
    if (factory_ == address(0)) revert ZeroAddress();
    factory = factory_;
  }

  // @notice This function will return the base URI of the contract
  function _baseURI() internal view virtual override returns (string memory) {
    return string(abi.encodePacked("https://meta.cruna.cc/vault/v1/", block.chainid.toString(), "/"));
  }

  // @notice This function will return the contract URI of the contract
  function contractURI() public view virtual returns (string memory) {
    return string(abi.encodePacked("https://meta.cruna.cc/vault/v1/", block.chainid.toString(), "/info"));
  }

  // @notice This function will mint a new token
  // @param to The address of the recipient
  function safeMintAndActivate(address to, uint256 amount) public virtual onlyFactory {
    _mintAndActivateByAmount(to, amount);
  }
}
