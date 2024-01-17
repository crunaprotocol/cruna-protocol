// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {CrunaManager} from "../../../manager/CrunaManager.sol";
import {CrunaManagerBase} from "../../../manager/CrunaManagerBase.sol";
import {IPlugin} from "../../../plugins/IPlugin.sol";

contract SomeSimplePlugin is IPlugin, CrunaManagerBase {
  error Forbidden();
  error NotUpgradeable();

  // Replace with the roles required by the plugin, if any, or delete it
  bytes4 public constant SOME_ROLE = bytes4(keccak256("SOME_ROLE"));

  CrunaManager public manager;

  // It pretends to be a proxy, if not the manager won't accept it
  function isProxy() external pure returns (bool) {
    return true;
  }

  function requiresToManageTransfer() external pure override returns (bool) {
    return false;
  }

  function init() external virtual {
    // replace with the name of your plugin
    if (_msgSender() != tokenAddress()) revert Forbidden();
    manager = CrunaManager(_msgSender());
  }

  function nameId() public virtual override returns (bytes4) {
    return bytes4(keccak256("SomeSimplePlugin"));
  }

  function doSomething() external {
    // some logic
  }

  function upgrade(address) external pure override {
    revert NotUpgradeable();
  }

  function requiresResetOnTransfer() external pure returns (bool) {
    return false;
  }

  function reset() external override {
    // do nothing because it does not need to be reset
  }
}
