// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBoundContract} from "./IBoundContract.sol";

/// @dev the ERC-165 identifier for this interface is `0xfc0c546a`
interface IBoundContractExtended is IBoundContract {
  function owner() external view returns (address);

  function tokenAddress() external view returns (address);

  function tokenId() external view returns (uint256);
}