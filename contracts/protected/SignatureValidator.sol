// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract SignatureValidator is EIP712 {
  error TimestampZero();

  constructor(string memory name, string memory version) EIP712(name, version) {}

  function signRequest(
    address owner,
    address actor,
    uint256 levelOrStatus,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external view returns (address) {
    if (timestamp == 0) revert TimestampZero();
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256("Auth(address owner,address actor,uint256 levelOrStatus,uint256 timestamp,uint256 validFor)"),
          owner,
          actor,
          levelOrStatus,
          timestamp,
          validFor
        )
      )
    );
    return ECDSA.recover(digest, signature);
  }
}
