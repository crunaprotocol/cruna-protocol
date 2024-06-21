// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ERC7656Service} from "erc7656/ERC7656Service.sol";
import {CrunaProtectedNFT} from "../token/CrunaProtectedNFT.sol";
import {INamed} from "../utils/INamed.sol";

import {ICommonBase} from "./ICommonBase.sol";

/**
 * @title CommonBase.sol
 * @notice Base contract for managers and services
 */
abstract contract CommonBase is ICommonBase, INamed, ERC7656Service {
  /**
   * @notice Error returned when the caller is not the token owner
   */
  modifier onlyTokenOwner() {
    if (owner() != msg.sender) revert NotTheTokenOwner();
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
