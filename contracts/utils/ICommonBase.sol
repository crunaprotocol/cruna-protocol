// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {CrunaProtectedNFT} from "../token/CrunaProtectedNFT.sol";

// import {console} from "hardhat/console.sol";

interface ICommonBase {
  error NotTheTokenOwner();

  function vault() external view returns (CrunaProtectedNFT);
}
