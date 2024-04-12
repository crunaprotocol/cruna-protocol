// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ICrunaService} from "./ICrunaService.sol";
import {CommonBase} from "../utils/CommonBase.sol";
//import "hardhat/console.sol";

/**
 * @title CrunaManagedService
 * @notice Base contract for services
 */
abstract contract CrunaService is ICrunaService, CommonBase {
  function _onBeforeInit() internal virtual {
    // does nothing
  }

  /// @dev see {ICrunaManagedService.sol-init}
  function init() external virtual {
    if (msg.sender != tokenAddress()) revert Forbidden();
    _onBeforeInit();
  }

  /// @dev see {IVersioned-version}
  function version() external pure virtual override returns (uint256) {
    return _version();
  }

  /// @dev see {ICrunaManagedService.sol-isERC6551Account}
  function isERC6551Account() external pure virtual returns (bool) {
    return false;
  }

  /// @dev see {IVersioned-version}
  function _version() internal pure virtual returns (uint256) {
    return 1_000_000;
  }

  function isManaged() external pure returns (bool) {
    return false;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
