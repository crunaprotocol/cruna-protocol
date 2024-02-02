// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WithDeployer {
  address private _deployer;

  constructor(address deployer_) {
    _deployer = deployer_;
  }

  function deployer() external view returns (address) {
    return _deployer;
  }
}
