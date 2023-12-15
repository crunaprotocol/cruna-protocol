// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

//import "hardhat/console.sol";

// @dev This contract is used to validate signatures.
//   It is based on EIP712 and supports typed messages V4.
contract SignatureValidator is EIP712 {
  using ECDSA for bytes32;

  error TimestampInvalidOrExpired();

  constructor() EIP712("Cruna", "1") {}

  function _validate(uint256 timeValidation) internal view {
    uint256 timestamp = timeValidation / 1e6;
    if (timestamp > block.timestamp || timestamp < block.timestamp - (timeValidation % 1e6)) revert TimestampInvalidOrExpired();
  }

  // @dev This function validates a signature trying to be as flexible as possible.
  //   As long as called inside the same contract, the cost adding some more parameters is negligible.
  //   Calling it from other contracts can be expensive. Use a delegate call to reduce the cost.
  // @param scope The scope of the signature.
  // @param owner The owner of the token.
  // @param actor The actor being authorized.
  //   It can be address(0) if the parameter is not needed.
  // @param tokenAddress The address of the token.
  // @param tokenId The id of the token.
  // @param extra The extra
  // @param extra2 The extra2
  // @param extra3 The extra3
  // @param timeValidation A combination of timestamp and validity of the signature.
  //   To be readable, the value is calculated as
  //     timestamp * 1e6 + validity
  // @param Returns the signer of the signature.
  function recoverSigner(
    bytes32 scope,
    address owner,
    address actor,
    address tokenAddress,
    uint256 tokenId,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
    uint256 timeValidation,
    bytes calldata signature
  ) public view returns (address) {
    _validate(timeValidation);
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "Auth(bytes32 scope,address owner,address actor,address tokenAddress,uint256 tokenId,uint256 extra,uint256 extra2,uint256 extra3,uint256 timeValidation)"
            ),
            scope,
            owner,
            actor,
            tokenAddress,
            tokenId,
            extra,
            extra2,
            extra3,
            timeValidation
          )
        )
      ).recover(signature);
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
