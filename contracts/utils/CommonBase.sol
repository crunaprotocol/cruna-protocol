// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {TokenLinkedContract} from "../utils/TokenLinkedContract.sol";
import {CrunaProtectedNFT} from "../token/CrunaProtectedNFT.sol";
import {SignatureValidator} from "../utils/SignatureValidator.sol";
import {INamed} from "../utils/INamed.sol";

import {ICommonBase} from "./ICommonBase.sol";
import {Actor} from "../manager/Actor.sol";

/**
 * @title CommonBase.sol
 * @notice Base contract for managers and plugins
 */
abstract contract CommonBase is ICommonBase, INamed, Context, Actor, TokenLinkedContract, SignatureValidator {
  /**
   * @notice Error returned when the caller is not the token owner
   */
  modifier onlyTokenOwner() {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  /**
   * @notice Returns the name id of the contract
   */
  function nameId() external view override returns (bytes4) {
    return _nameId();
  }

  /**
   * @notice Internal function that must be overridden by the contract to
   * return the name id of the contract
   */
  function _nameId() internal view virtual returns (bytes4);

  /**
   * @notice Returns the vault, i.e., the CrunaProtectedNFT contract
   */
  function vault() external view virtual returns (CrunaProtectedNFT) {
    return _vault();
  }

  /**
   * @notice Returns the keccak256 of a string variable.
   * It saves gas compared to keccak256(abi.encodePacked(string)).
   * @param input The string to hash
   */
  function _hashString(string memory input) internal pure returns (bytes32 result) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Load the pointer to the free memory slot
      let ptr := mload(0x40)
      // Copy data using Solidity's default encoding, which includes the length
      mstore(ptr, mload(add(input, 32)))
      // Calculate keccak256 hash
      result := keccak256(ptr, mload(input))
    }
  }

  /**
   * @notice Returns the equivalent of bytes4(keccak256(str).
   * @param str The string to hash
   */
  function _stringToBytes4(string memory str) internal pure returns (bytes4) {
    return bytes4(_hashString(str));
  }

  /**
   * @notice Returns the vault, i.e., the CrunaProtectedNFT contract
   */
  function _vault() internal view virtual returns (CrunaProtectedNFT) {
    return CrunaProtectedNFT(tokenAddress());
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
