// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {CrunaPluginBase} from "../../../../plugins/CrunaPluginBase.sol";

contract SomePlugin is CrunaPluginBase {
  // Replace with the roles required by the plugin, if any, or delete it
  bytes4 public constant SOME_OTHER_ROLE = bytes4(keccak256("SOME_ROLE"));

  function nameId() public view virtual override(CrunaPluginBase) returns (bytes4) {
    return bytes4(keccak256("SomePlugin"));
  }

  function requiresToManageTransfer() external pure override returns (bool) {
    return false;
  }

  function doSomething() external {
    // some logic
  }

  function reset() external override {
    if (_msgSender() != address(manager)) revert Forbidden();
    _reset();
  }

  function requiresResetOnTransfer() external pure returns (bool) {
    return true;
  }

  function _reset() internal {
    // reset to initial state
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}