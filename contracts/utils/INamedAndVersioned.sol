// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {IVersioned} from "./IVersioned.sol";
import {INamed} from "./INamed.sol";

interface INamedAndVersioned is INamed, IVersioned {}
