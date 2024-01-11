// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract TetherUSD is ERC20, Ownable2Step {
  constructor(address initialOwner) ERC20("Tether USD", "USDT") Ownable(initialOwner) {}

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return 6;
  }
}
