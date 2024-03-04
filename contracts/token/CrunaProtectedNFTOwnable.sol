// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {CrunaProtectedNFT} from "./CrunaProtectedNFT.sol";

//import {console} from "hardhat/console.sol";

// @dev This contract is a base for NFTs with protected transfers.
//   We advise to use CrunaProtectedNFTTimeControlled.sol instead, since it allows
//   a better governance.
abstract contract CrunaProtectedNFTOwnable is CrunaProtectedNFT, Ownable2Step {
  error NotTheOwner();

  constructor(string memory name_, string memory symbol_, address admin) CrunaProtectedNFT(name_, symbol_) Ownable(admin) {}

  function _canManage(bool) internal view virtual override {
    if (_msgSender() != owner()) revert NotTheOwner();
  }
}
