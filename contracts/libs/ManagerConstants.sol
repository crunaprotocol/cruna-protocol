// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

// import {console} from "hardhat/console.sol";

library ManagerConstants {
  function maxActors() internal pure returns (uint256) {
    return 16;
  }

  function protectorId() internal pure returns (bytes4) {
    return 0x245ac14a;
  }

  function safeRecipientId() internal pure returns (bytes4) {
    return 0xb58bf73a;
  }

  function gasToEmitLockedEvent() internal pure returns (uint256) {
    return 10_000;
  }

  function gasToResetPlugin() internal pure returns (uint256) {
    return 17_000;
  }
}
