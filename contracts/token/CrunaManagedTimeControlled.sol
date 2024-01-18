// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {CrunaManagedBase} from "./CrunaManagedBase.sol";
import {TimelockController, FlexiTimelockController} from "../utils/FlexiTimelockController.sol";

//import {console} from "hardhat/console.sol";

// @dev This contract is a base for NFTs with protected transfers.
//   It implements best practices for governance and timelock.
abstract contract CrunaManagedTimeControlled is CrunaManagedBase, FlexiTimelockController {
  error NotAuthorized();

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address admin
  ) CrunaManagedBase(name_, symbol_) FlexiTimelockController(minDelay, proposers, executors, admin) {}

  function _canManage(bool isInitializing) internal view virtual override {
    if (isInitializing) {
      if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert NotAuthorized();
    } else if (_msgSender() != address(this)) revert MustCallThroughTimeController();
  }

  // @dev See {ERC165-supportsInterface}.
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(TimelockController, CrunaManagedBase) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
