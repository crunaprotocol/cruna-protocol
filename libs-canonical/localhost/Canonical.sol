// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "../canonical/ICrunaGuardian.sol";
import {IERC7656Registry} from "../erc/IERC7656Registry.sol";

/**
 * @title Canonical
 * @notice Returns the address where registries and guardian have been deployed
 * @dev There are two set of addresses. In both, the registry are on the same addresses, but
 * the guardian has a different address for testing and deployment to localhost (using the 2nd
 * and 3rd hardhat standard wallets as proposer and executor).
 * This contract is for development and testing purposes only. When the package is published
 * to Npm, the addresses will be replaced by the actual addresses of the deployed contracts.
 */
library Canonical {

  /**
   * @notice Returns the ERC7656Registry contract
   */
  function erc7656Registry() internal pure returns (IERC7656Registry) {
    return IERC7656Registry(0x765600Cc5dFdC3C36259Cb5b938624ebd99D8F33);
  }

  /**
   * @notice Returns the ERC6551Registry contract
   */
  function erc6551Registry() internal pure returns (IERC6551Registry) {
    return IERC6551Registry(0x000000006551c19487814612e58FE06813775758);
  }

  /**
   * @notice Returns the CrunaGuardian contract
   */
  function crunaGuardian() internal pure returns (ICrunaGuardian) {
    return ICrunaGuardian(0x1AdF15952De891f68772e716ED56EBa66c489402);
  }
}
