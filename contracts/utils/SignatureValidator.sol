// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Versioned} from "./Versioned.sol";

contract SignatureValidator is EIP712, Versioned {
  using ECDSA for bytes32;

  constructor(string memory name, string memory version) EIP712(name, version) {}

  function recoverSigner2(
    address address1,
    address address2,
    uint256 integer1,
    uint256 integer2,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external view returns (address) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "Auth(address address1,address address2,uint256 integer1,uint256 integer2,uint256 timestamp,uint256 validFor)"
            ),
            address1,
            address2,
            integer1,
            integer2,
            timestamp,
            validFor
          )
        )
      ).recover(signature);
  }

  // We put this function here just to be ready for more complex signatures in the future, without having to deploy a new contract
  function recoverSigner3(
    address address1,
    address address2,
    address address3,
    uint256 integer1,
    uint256 integer2,
    uint256 integer3,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external view returns (address) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "Auth(address address1,address address2,address address3,uint256 integer1,uint256 integer2,uint256 integer3,uint256 timestamp,uint256 validFor)"
            ),
            address1,
            address2,
            address3,
            integer1,
            integer2,
            integer3,
            timestamp,
            validFor
          )
        )
      ).recover(signature);
  }
}
