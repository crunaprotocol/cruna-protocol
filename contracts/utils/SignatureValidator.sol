// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Versioned} from "./Versioned.sol";

contract SignatureValidator is EIP712, Versioned {
  using ECDSA for bytes32;

  constructor(string memory name, string memory version) EIP712(name, version) {}

  function recoverSigner(
    address owner,
    address actor,
    uint256 tokenId,
    uint256 extraValue,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external view returns (address) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "Auth(address owner,address actor,uint256 tokenId,uint256 extraValue,uint256 timestamp,uint256 validFor)"
            ),
            owner,
            actor,
            tokenId,
            extraValue,
            timestamp,
            validFor
          )
        )
      ).recover(signature);
  }
}
