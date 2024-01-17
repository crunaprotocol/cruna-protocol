// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {CrunaManager} from "../../../manager/CrunaManager.sol";
import {CrunaManagerBase} from "../../../manager/CrunaManagerBase.sol";
import {IPlugin} from "../../../plugins/IPlugin.sol";

contract SomePlugin is IPlugin, CrunaManagerBase {
  error Forbidden();

  // Replace with the roles required by the plugin, if any, or delete it
  bytes4 public constant SOME_OTHER_ROLE = bytes4(keccak256("SOME_ROLE"));

  CrunaManager public manager;

  function nameId() public virtual override returns (bytes4) {
    return bytes4(keccak256("SomePlugin"));
  }

  function requiresToManageTransfer() external pure override returns (bool) {
    return false;
  }

  function init() external virtual {
    // replace with the name of your plugin
    if (_msgSender() != tokenAddress()) revert Forbidden();
    manager = CrunaManager(_msgSender());
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
