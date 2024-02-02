// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

import {WithDeployer} from "./WithDeployer.sol";

//import "hardhat/console.sol";

// This version of ERC6551AccountProxy is modified to work with the OpenZeppelin Contracts v5
// The original version can be found in https://github.com/erc6551/reference
contract ERC6551AccountProxy is Proxy, WithDeployer {
  error InvalidImplementation();

  address public immutable DEFAULT_IMPLEMENTATION;

  receive() external payable virtual {
    _fallback();
  }

  constructor(address _defaultImplementation, address deployer_) WithDeployer(deployer_) {
    if (_defaultImplementation == address(0)) revert InvalidImplementation();
    DEFAULT_IMPLEMENTATION = _defaultImplementation;
  }

  function _implementation() internal view virtual override returns (address) {
    address implementation = ERC1967Utils.getImplementation();

    if (implementation == address(0)) return DEFAULT_IMPLEMENTATION;

    return implementation;
  }

  function _fallback() internal virtual override {
    if (msg.data.length == 0) {
      if (ERC1967Utils.getImplementation() == address(0)) {
        ERC1967Utils.upgradeToAndCall(DEFAULT_IMPLEMENTATION, "");
        _delegate(DEFAULT_IMPLEMENTATION);
      }
    } else {
      super._fallback();
    }
  }
}
