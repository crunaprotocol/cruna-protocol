// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {CrunaProtectedNFT} from "./CrunaProtectedNFT.sol";

/**
 * @title CrunaProtectedNFTTimeControlled
 * @notice This contract is a base for NFTs with protected transfers.
 * It implements best practices for governance and timelock.
 */
abstract contract CrunaProtectedNFTTimeControlled is CrunaProtectedNFT, TimelockController {
  /**
   * @notice Error returned when the caller is not authorized
   */
  error NotAuthorized();

  /**
   * @notice Error returned when the function is not called through the TimelockController
   */
  error MustCallThroughTimeController();

  /**
   * @notice construct the contract with a given name, symbol, minDelay, proposers, executors, and admin.
   * @param name_ The name of the token.
   * @param symbol_ The symbol of the token.
   * @param minDelay The minimum delay for the time lock.
   * @param proposers The initial proposers.
   * @param executors The initial executors.
   * @param admin The admin of the contract (they should later renounce to the role).
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address admin
  ) CrunaProtectedNFT(name_, symbol_) TimelockController(minDelay, proposers, executors, admin) {}

  /// @dev see {ERC165-supportsInterface}.
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(TimelockController, CrunaProtectedNFT) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /// @dev see {CrunaProtectedNFT-_canManage}
  function _canManage(bool isInitializing) internal view virtual override {
    if (isInitializing) {
      if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert NotAuthorized();
    } else if (_msgSender() != address(this)) revert MustCallThroughTimeController();
  }
}
