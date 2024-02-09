// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SignatureValidator} from "../utils/SignatureValidator.sol";

contract ValidatorMock is SignatureValidator {
  function _canPreApprove(bytes4, address, address) internal pure virtual override returns (bool) {
    return true;
  }
}
