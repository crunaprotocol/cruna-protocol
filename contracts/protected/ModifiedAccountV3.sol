// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

import {OPAddressAliasHelper} from "@tokenbound/contracts/lib/OPAddressAliasHelper.sol";

import {IAccountGuardian} from "@tokenbound/contracts/interfaces/IAccountGuardian.sol";

import {Protected} from "./Protected.sol";

/**
 * @title Tokenbound ERC-6551 Account Implementation
 */
contract ModifiedAccountV3 is Context {
  IAccountGuardian public immutable guardian;

  /**
   * @param _guardian The AccountGuardian address
   */
  constructor(address _guardian) {
    guardian = IAccountGuardian(_guardian);
  }

  function isValidSigner(address signer, bytes calldata) external view virtual returns (bytes4) {
    if (_isValidSigner(signer)) {
      return this.isValidSigner.selector;
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
    bytes memory footer = new bytes(0x60);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
    }

    return abi.decode(footer, (uint256, address, uint256));
  }

  function owner() public view virtual returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = token();
    if (chainId != block.chainid) return address(0);

    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  function _isValidSigner(address signer) internal view virtual returns (bool) {
    return signer == owner();
  }

  function vault() public view returns (Protected) {
    (, address tokenContract_, ) = token();
    return Protected(tokenContract_);
  }

  function tokenContract() public view returns (address) {
    (, address tokenContract_, ) = token();
    return tokenContract_;
  }

  function tokenId() public view returns (uint256) {
    (, , uint256 tokenId_) = token();
    return tokenId_;
  }
}
