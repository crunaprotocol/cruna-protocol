// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract UselessWeapons is ERC1155, Ownable2Step {
  constructor(string memory baseUri) ERC1155(baseUri) {}

  function setURI(string memory newuri_) public onlyOwner {
    _setURI(newuri_);
  }

  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }
}
