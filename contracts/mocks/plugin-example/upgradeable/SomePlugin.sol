// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {Manager} from "../../../manager/Manager.sol";
import {ManagerBase} from "../../../manager/ManagerBase.sol";
import {IPlugin} from "../../../plugins/IPlugin.sol";

contract SomePlugin is IPlugin, ManagerBase {
  error Forbidden();

  // Replace with the roles required by the plugin, if any, or delete it
  bytes4 public constant SOME_OTHER_ROLE = bytes4(keccak256("SOME_ROLE"));

  Manager public manager;

  function nameHash() public virtual override returns (bytes4) {
    return bytes4(keccak256("SomePlugin"));
  }

  function requiresToManageTransfer() external pure override returns (bool) {
    return false;
  }

  function init() external virtual {
    // replace with the name of your plugin
    if (_msgSender() != tokenAddress()) revert Forbidden();
    manager = Manager(_msgSender());
  }

  function doSomething() external {
    // some logic
  }

  function reset() external override {
    if (_msgSender() != address(manager)) revert Forbidden();
    _reset();
  }

  function _reset() internal {
    // reset to initial state
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
