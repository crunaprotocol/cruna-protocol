// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

//import "hardhat/console.sol";

// @dev This contract is used to validate signatures.
//   It is based on EIP712 and supports typed messages V4.
abstract contract SignatureValidator is EIP712, Context {
  using ECDSA for bytes32;

  error TimestampInvalidOrExpired();

  mapping(bytes32 => address) public preApprovals;

  constructor() EIP712("Cruna", "1") {}

  // must be implemented by managers and plugins
  function _canPreApprove(address signer) internal view virtual returns (bool);

  function _validate(uint256 timeValidation) internal view {
    uint256 timestamp = timeValidation / 1e6;
    if (timestamp > block.timestamp || timestamp < block.timestamp - (timeValidation % 1e6)) revert TimestampInvalidOrExpired();
  }

  // @dev This function validates a signature trying to be as flexible as possible.
  //   As long as called inside the same contract, the cost adding some more parameters is negligible. Instead, calling it from other contracts can be expensive.
  // @param selector The selector of the function being called.
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
    bytes4 selector,
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
    bytes32 hash = _hashData(selector, owner, actor, tokenAddress, tokenId, extra, extra2, extra3, timeValidation);
    if (signature.length == 0) {
      return preApprovals[hash];
    } else {
      return _hashTypedDataV4(hash).recover(signature);
    }
  }

  function preApprove(
    bytes4 selector,
    address owner,
    address actor,
    address tokenAddress,
    uint256 tokenId,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
    uint256 timeValidation
  ) external {
    _canPreApprove(_msgSender());
    bytes32 hash = _hashData(selector, owner, actor, tokenAddress, tokenId, extra, extra2, extra3, timeValidation);
    preApprovals[hash] = _msgSender();
  }

  function _hashData(
    bytes4 selector,
    address owner,
    address actor,
    address tokenAddress,
    uint256 tokenId,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
    uint256 timeValidation
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "Auth(bytes4 selector,address owner,address actor,address tokenAddress,uint256 tokenId,uint256 extra,uint256 extra2,uint256 extra3,uint256 timeValidation)"
          ),
          selector,
          owner,
          actor,
          tokenAddress,
          tokenId,
          extra,
          extra2,
          extra3,
          timeValidation
        )
      );
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
