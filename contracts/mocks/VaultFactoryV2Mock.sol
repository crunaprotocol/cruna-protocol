// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VaultFactory} from "../factory/VaultFactory.sol";

contract VaultFactoryV2Mock is VaultFactory {
  function version() public pure virtual override returns (uint256) {
    return 2e6;
  }
}
