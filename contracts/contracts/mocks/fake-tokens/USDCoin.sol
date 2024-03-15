// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract USDCoin is ERC20, Ownable2Step {
  constructor(address initialOwner) ERC20("USD Coin", "USDC") Ownable(initialOwner) {}

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }
}
