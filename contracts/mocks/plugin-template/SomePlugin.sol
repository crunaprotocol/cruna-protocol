// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {Manager} from "../../manager/Manager.sol";
import {Guardian, ManagerBase} from "../../manager/ManagerBase.sol";
import {Versioned} from "../../utils/Versioned.sol";
import {IPlugin} from "../../plugins/IPlugin.sol";

contract SomePlugin is IPlugin, Versioned, ManagerBase {
  error Forbidden();

  bytes32 public constant SOME_ROLE = keccak256("SOME_ROLE");

  Manager public manager;

  function init(address guardian_) external virtual {
    _nameHash = keccak256("SomePlugin");
    if (msg.sender != tokenAddress()) revert Forbidden();
    guardian = Guardian(guardian_);
    manager = Manager(msg.sender);
  }

  function pluginRoles() external pure virtual returns (bytes32[] memory) {
    bytes32[] memory roles = new bytes32[](1);
    roles[0] = SOME_ROLE;
    return roles;
  }

  function doSomething() external {
    // some logic
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
