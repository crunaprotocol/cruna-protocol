// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {IVersioned} from "./IVersioned.sol";

interface INamedAndVersioned is IVersioned {
  function nameId() external returns (bytes4);
}
