// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {CrunaProtectedNFT} from "./CrunaProtectedNFT.sol";

/**
 * @title CrunaProtectedNFTOwnable
 * @notice This contract is a base for NFTs with protected transfers.
 * We advise to use CrunaProtectedNFTTimeControlled.sol instead, since it allows
 * a better governance.
 */
abstract contract CrunaProtectedNFTOwnable is CrunaProtectedNFT, Ownable2Step {
  /**
   * @notice Error returned when the caller is not the owner
   */
  error NotTheOwner();

  /**
   * @notice Construct the contract with a given name, symbol, and admin.
   * @param name_ The name of the token.
   * @param symbol_ The symbol of the token.
   * @param admin The owner of the contract
   */
  constructor(string memory name_, string memory symbol_, address admin) CrunaProtectedNFT(name_, symbol_) Ownable(admin) {}

  /// @dev see {CrunaProtectedNFT-_canManage}
  function _canManage(bool) internal view virtual override {
    if (_msgSender() != owner()) revert NotTheOwner();
  }
}
