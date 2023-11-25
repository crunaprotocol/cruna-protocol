// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Versioned} from "./Versioned.sol";

// @dev This contract is used to validate signatures.
//   It is based on EIP712 and supports typed messages V4.
contract SignatureValidator is EIP712, Versioned {
  using ECDSA for bytes32;

  error UnsupportedScope(string scope);

  constructor(string memory name, string memory version) EIP712(name, version) {}

  // @dev This function lists the supported scopes.
  // @return An integer with the supported scope.
  //   It reverts if the scope is not supported.
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

  // @dev This function validates a signature.
  // @param scope The scope of the signature.
  // @param owner The owner of the token.
  // @param actor The actor being authorized.
  //   It can be address(0) if the parameter is not needed.
  // @param tokenId The id of the token.
  // @param status The status
  // @param timestamp The timestamp of the signature.
  // @param validFor The validity of the signature.
  // @param Returns the signer of the signature.
  function recoverSigner(
    uint256 scope,
    address owner,
    address actor,
    uint256 tokenId,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external view returns (address) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "Auth(uint256 scope,address owner,address actor,uint256 tokenId,bool status,uint256 timestamp,uint256 validFor)"
            ),
            scope,
            owner,
            actor,
            tokenId,
            status,
            timestamp,
            validFor
          )
        )
      ).recover(signature);
  }
}
