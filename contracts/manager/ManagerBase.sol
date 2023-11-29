// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

//import {console} from "hardhat/console.sol";

contract ManagerBase {
  function token() public view virtual returns (uint256, address, uint256) {
    return ERC6551AccountLib.token();
  }

  function owner() public view virtual returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = token();
    if (chainId != block.chainid) return address(0);
    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  function tokenAddress() public view returns (address) {
    (, address tokenContract_, ) = token();
    return tokenContract_;
  }

  function tokenId() public view returns (uint256) {
    (, , uint256 tokenId_) = token();
    return tokenId_;
  }
}
