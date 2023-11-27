// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

//import {console} from "hardhat/console.sol";

contract ERC6551AccountEmulator is IERC1271 {
  function isValidSigner(address signer, bytes calldata) external view virtual returns (bytes4) {
    if (_isValidSigner(signer)) {
      return IERC6551Account.isValidSigner.selector;
    }
    return bytes4(0);
  }

  function isValidSignature(bytes32 hash, bytes memory signature) external view virtual returns (bytes4 magicValue) {
    bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

    if (isValid) {
      return IERC1271.isValidSignature.selector;
    }

    return bytes4(0);
  }

  function token() public view virtual returns (uint256, address, uint256) {
    return ERC6551AccountLib.token();
  }

  function owner() public view virtual returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = token();
    if (chainId != block.chainid) return address(0);

    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  function _isValidSigner(address signer) internal view virtual returns (bool) {
    return signer == owner();
  }

  // end ERC6551

  function tokenAddress() public view returns (address) {
    (, address tokenContract_, ) = token();
    return tokenContract_;
  }

  function tokenId() public view returns (uint256) {
    (, , uint256 tokenId_) = token();
    return tokenId_;
  }
}
