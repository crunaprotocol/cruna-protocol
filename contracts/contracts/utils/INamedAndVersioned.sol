// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IVersioned} from "./IVersioned.sol";
import {INamed} from "./INamed.sol";

/**
 * @title INamedAndVersioned
 * @notice Combines INamed and IVersioned
 */
interface INamedAndVersioned is INamed, IVersioned {}
