// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

import {Canonical} from "../libs/Canonical.sol";

/**
 * @title Deployed
 * @notice This contract manages deploy-related functions
 */
abstract contract Deployed {
  /// @dev see {ICrunaProtectedNFT-isDeployed}
  function _isDeployed(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    bool isERC6551Account
  ) internal view virtual returns (bool) {
    address _addr = _addressOfDeployed(implementation, salt, tokenAddress, tokenId, isERC6551Account);
    uint32 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(_addr)
    }
    return (size != 0);
  }

  /**
   * @notice Internal function to return the address of a deployed token bound contract
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @param isERC6551Account If true, the tokenId has been deployed via ERC6551Registry, if false, via ERC7656Registry
   */
  function _addressOfDeployed(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    bool isERC6551Account
  ) internal view virtual returns (address) {
    return
      ERC6551AccountLib.computeAddress(
        isERC6551Account ? address(Canonical.erc6551Registry()) : address(Canonical.erc7656Registry()),
        implementation,
        salt,
        block.chainid,
        tokenAddress,
        tokenId
      );
  }

  /**
   * @notice This function deploys a token-linked contract (manager or plugin)
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @param isERC6551Account If true, the tokenId will be deployed via ERC6551Registry,
   * if false, via ERC7656Registry
   */
  function _deploy(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    bool isERC6551Account
  ) internal virtual returns (address) {
    if (isERC6551Account) {
      return Canonical.erc6551Registry().createAccount(implementation, salt, block.chainid, tokenAddress, tokenId);
    }
    return Canonical.erc7656Registry().create(implementation, salt, block.chainid, tokenAddress, tokenId);
  }
}
