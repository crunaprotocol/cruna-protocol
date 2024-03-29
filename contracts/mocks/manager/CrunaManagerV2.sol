// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CrunaManager} from "../../manager/CrunaManager.sol";

contract CrunaManagerV2 is CrunaManager {
  bool public migrated;

  function version() external pure virtual override returns (uint256) {
    return 1_002_000;
  }

  // new function in V2
  function bytes4ToHexString(bytes4 _bytes) public pure returns (string memory) {
    bytes memory byteArray = new bytes(8);
    unchecked {
      for (uint256 i; i < 4; i++) {
        uint8 currentByte = uint8(_bytes[i]);
        byteArray[2 * i] = _nibbleToHexChar(currentByte / 16);
        byteArray[2 * i + 1] = _nibbleToHexChar(currentByte % 16);
      }
    }
    return string(abi.encodePacked("0x", string(byteArray)));
  }

  function _nibbleToHexChar(uint8 _nibble) internal pure returns (bytes1) {
    if (_nibble < 10) {
      return bytes1(uint8(bytes1("0")) + _nibble);
    } else {
      return bytes1(uint8(bytes1("a")) + _nibble - 10);
    }
  }

  function migrate(uint256) external virtual override {
    if (_msgSender() != address(this)) revert Forbidden();
    migrated = true;
  }
}
