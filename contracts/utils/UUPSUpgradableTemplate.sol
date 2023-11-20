// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>
// https://github.com/sullof/soliutils
// Testing for this code is in the original repo.

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract UUPSUpgradableTemplate is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  // solhint-disable-next-line
  function __UUPSUpgradableTemplate_init() internal initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}
