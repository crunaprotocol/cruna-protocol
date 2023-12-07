// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {Manager} from "../../../manager/Manager.sol";
import {ManagerBase} from "../../../manager/ManagerBase.sol";
import {IPlugin} from "../../../plugins/IPlugin.sol";

contract SomeSimplePlugin is IPlugin, ManagerBase {
  error Forbidden();
  error NotUpgradeable();

  // Replace with the roles required by the plugin, if any, or delete it
  bytes32 public constant SOME_ROLE = keccak256("SOME_ROLE");

  Manager public manager;

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
    manager = Manager(_msgSender());
  }

  function nameHash() public virtual override returns (bytes32) {
    return keccak256("SomeSimplePlugin");
  }

  function pluginRoles() external pure virtual returns (bytes32[] memory) {
    bytes32[] memory roles = new bytes32[](1);
    // return your roles, if any
    roles[0] = SOME_ROLE;
    return roles;
  }

  function doSomething() external {
    // some logic
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  function upgrade(address) external pure override {
    revert NotUpgradeable();
  }
}
