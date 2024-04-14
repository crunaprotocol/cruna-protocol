// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {Initializable, ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {CrunaService} from "../../services/CrunaService.sol";

//import "hardhat/console.sol";

contract FungibleService is CrunaService, Initializable, ERC20Upgradeable, ERC20PermitUpgradeable {
  using Strings for uint256;

  function mint(address to, uint256 amount) public onlyTokenOwner {
    _mint(to, amount);
  }

  function _nameId() internal view virtual override returns (bytes4) {
    return bytes4(keccak256("FungibleService"));
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(string memory name, string memory symbol) public initializer {
    __ERC20_init(name, symbol);
    __ERC20Permit_init(name);
  }

  function extraName() external view returns (string memory) {
    return string(abi.encodePacked("FT ", _vault().name(), " #", tokenId().toString()));
  }

  function _onBeforeInit(bytes memory data) internal override {
    (string memory name, string memory symbol) = abi.decode(data, (string, string));
    initialize(name, symbol);
  }
}
