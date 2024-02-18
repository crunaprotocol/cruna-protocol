// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SignatureValidator} from "../../utils/SignatureValidator.sol";

contract SignatureValidatorMock is SignatureValidator {
  function _canPreApprove(bytes4, address, address) internal pure virtual override returns (bool) {
    return true;
  }

  function _isProtected() internal view virtual override returns (bool) {
    return false;
  }

  function _isProtector(address) internal view virtual override returns (bool) {
    return false;
  }

  function hashData(
    bytes4 selector,
    address owner,
    address actor,
    address tokenAddress,
    uint256 tokenId,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
    uint256 timeValidation
  ) external pure returns (bytes32) {
    return _hashData(selector, owner, actor, tokenAddress, tokenId, extra, extra2, extra3, timeValidation);
  }
}
