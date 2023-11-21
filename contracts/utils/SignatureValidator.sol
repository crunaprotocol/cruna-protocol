// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Versioned} from "./Versioned.sol";

contract SignatureValidator is EIP712, Versioned {
  using ECDSA for bytes32;

  error UnsupportedScope(string scope);

  constructor(string memory name, string memory version) EIP712(name, version) {}

  function getSupportedScope(string memory scope) public pure returns (uint256) {
    bytes32 scopeHash = keccak256(abi.encodePacked(scope));
    if (scopeHash == keccak256("PROTECTOR")) {
      return 1;
    } else if (scopeHash == keccak256("SENTINEL")) {
      return 2;
    } else if (scopeHash == keccak256("SAFE_RECIPIENT")) {
      return 3;
    } else if (scopeHash == keccak256("PROTECTED_TRANSFER")) {
      return 4;
    } else {
      revert UnsupportedScope(scope);
    }
  }

  function recoverSigner(
    uint256 scope,
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
              "Auth(uint256 scope,address owner,address actor,uint256 tokenId,uint256 extraValue,uint256 timestamp,uint256 validFor)"
            ),
            scope,
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
