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
  /**
   * @notice The function to be executed before init
   * @dev must be implemented in the service
   */
  function _onBeforeInit(bytes memory data) internal virtual;

  /// @dev see {ICrunaManagedService.sol-init}
  function init(bytes memory data) external virtual {
    if (msg.sender != tokenAddress()) revert Forbidden();
    _onBeforeInit(data);
  }

  /**
   * @notice Returns the version of the contract.
   * The format is similar to semver, where any element takes 3 digits.
   * For example, version 1.2.14 is 1_002_014.
   */
  function version() external pure virtual override returns (uint256) {
    return _version();
  }

  /// @dev see {ICrunaManagedService.sol-isERC6551Account}
  function isERC6551Account() external pure virtual returns (bool) {
    return false;
  }

  /**
   * @notice Returns the version of the contract.
   * The format is similar to semver, where any element takes 3 digits.
   * For example, version 1.2.14 is 1_002_014.
   */
  function _version() internal pure virtual returns (uint256) {
    return 1_000_000;
  }

  function isManaged() external pure returns (bool) {
    return false;
  }

  function serviceKey() external view virtual returns (bytes32) {
    return _serviceKey();
  }

  function _serviceKey() internal view virtual returns (bytes32) {
    return _salt() | bytes32((uint256(uint160(_implementation())) << 48) | uint256(uint32(_nameId())));
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
