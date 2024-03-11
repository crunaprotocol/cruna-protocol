// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {InheritanceCrunaPlugin} from "../../plugins/inheritance/InheritanceCrunaPlugin.sol";

contract SomeInheritancePlugin is InheritanceCrunaPlugin {
  function _nameId() internal pure virtual override returns (bytes4) {
    return bytes4(keccak256("SomeInheritancePlugin"));
  }

  function isERC6551Account() external pure override returns (bool) {
    return true;
  }
}
