// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Versioned} from "./Versioned.sol";

// @dev This contract is used to validate signatures.
//   It is based on EIP712 and supports typed messages V4.
contract SignatureValidator is EIP712, Versioned {
  using ECDSA for bytes32;

  constructor(string memory name, string memory version) EIP712(name, version) {}

  // @dev This function validates a signature.
  // @param scope The scope of the signature.
  //   For example keccak256("PROTECTOR").
  // @param owner The owner of the token.
  // @param actor The actor being authorized.
  //   It can be address(0) if the parameter is not needed.
  // @param tokenId The id of the token.
  // @param extraValue The extraValue
  // @param timestamp The timestamp of the signature.
  // @param validFor The validity of the signature.
  // @param Returns the signer of the signature.
  function recoverSetActorSigner(
    bytes32 scope,
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
              "Auth(bytes32 scope,address owner,address actor,uint256 tokenId,uint256 extraValue,uint256 timestamp,uint256 validFor)"
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

  // @dev This function validates a signature with 3 extra values
  //   It have redundant parameters to give plugins more flexibility
  //   If more parameters are needed, the plugin can encode the data in
  //   the extraValue using bitwise operators
  //   The function is supposed to be used by the plugin for its internal checks.
  // @param nameHash The nameHash of the plugin.
  // @param owner The owner of the token.
  // @param addr1 An address being authorized.
  //   It can be address(0) if the parameter is not needed.
  // @param tokenId The id of the token.
  // @param extraValue The first extraValue
  // @param extraValue2 The second extraValue
  // @param extraValue3 The third extraValue
  // @param timestamp The timestamp of the signature.
  // @param validFor The validity of the signature.
  // @param Returns the signer of the signature.
  function recoverPluginSigner(
    bytes32 nameHash,
    address owner,
    address addr,
    uint256 tokenId,
    uint256 extraValue,
    uint256 extraValue2,
    uint256 extraValue3,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external view returns (address) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "Auth(bytes32 nameHash,address owner,address addr,uint256 tokenId,uint256 extraValue,uint256 extraValue2,uint256 extraValue3,uint256 timestamp,uint256 validFor)"
            ),
            nameHash,
            owner,
            addr,
            tokenId,
            extraValue,
            extraValue2,
            extraValue3,
            timestamp,
            validFor
          )
        )
      ).recover(signature);
  }
}
