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

// import {console} from "hardhat/console.sol";

/**
  @title CrunaManagerBase.sol
  @dev Base contract for managers and plugins
*/
abstract contract CommonBase is ICommonBase, INamed, Context, Actor, TokenLinkedContract, SignatureValidator {
  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  modifier onlyTokenOwner() {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  // must be overridden
  function nameId() public view virtual override returns (bytes4) {
    return bytes4(0);
  }

  function vault() external view virtual returns (CrunaProtectedNFT) {
    return _vault();
  }

  /**
   * @dev Returns the keccak256 of a string variable.
   * It saves gas compared to keccak256(abi.encodePacked(string)).
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

  function _stringToBytes4(string memory str) internal pure returns (bytes4) {
    return bytes4(_hashString(str));
  }

  function _vault() internal view virtual returns (CrunaProtectedNFT) {
    return CrunaProtectedNFT(tokenAddress());
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
