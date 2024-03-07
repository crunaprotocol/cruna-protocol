// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {InheritanceCrunaPlugin} from "../../plugins/inheritance/InheritanceCrunaPlugin.sol";
import {IVersioned} from "../../utils/IVersioned.sol";
import {CrunaPluginBase} from "../../plugins/CrunaPluginBase.sol";

contract InheritanceCrunaPluginV2 is InheritanceCrunaPlugin {
  uint256 public constant SOME_VARIABLE = 3;

  function version() public pure virtual override(IVersioned, CrunaPluginBase) returns (uint256) {
    return 1_000_002;
  }
}
