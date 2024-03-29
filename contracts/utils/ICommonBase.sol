// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {CrunaProtectedNFT} from "../token/CrunaProtectedNFT.sol";

/**
 * @title ICommonBase
 */
interface ICommonBase {
  /**
   * @notice Error returned when the caller is not the token owner
   */
  error NotTheTokenOwner();

  /**
   * @notice Returns the vault, i.e., the CrunaProtectedNFT contract
   */
  function vault() external view returns (CrunaProtectedNFT);
}
