// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IManagedNFT} from "./IManagedNFT.sol";

// Author: Francesco Sullo <francesco@sullo.co>
interface ICrunaProtectedNFT is IManagedNFT, IERC721 {
  /**
   * @dev Optimized configuration structure for the generic NFT
   *
   * Elements:
   * - progressiveTokenIds is used to allow the upgrade of the default manager implementation. It is used to assure that the manager can be upgraded in a safe way.
   * - allowUntrustedTransfers is used by the managers to allow untrusted plugins to transfer the tokens. Typically, we would set it true for testnets and false for mainnets.
   * - nextTokenId is the next tokenId to be used. It is used to mint new tokens if progressiveTokenIds is true. Notice the limit to a uint112.
   * - maxTokenId is the maximum tokenId that can be minted. It is used to limit the minting of new tokens. Notice the limit to a uint112.
   * - managerHistoryLength is the length of the manager history.
   */
  struct NftConf {
    bool progressiveTokenIds;
    bool allowUntrustedTransfers;
    uint112 nextTokenId;
    uint112 maxTokenId;
    uint8 managerHistoryLength;
    // for future changes
    uint8 unusedField;
  }

  struct ManagerHistory {
    uint112 firstTokenId;
    uint112 lastTokenId;
    address managerAddress;
  }

  // events

  event DefaultManagerUpgrade(address indexed newManagerProxy);
  event MaxTokenIdChange(uint112 maxTokenId);

  // errors

  error NotTransferable();
  error NotTheManager();
  error ZeroAddress();
  error AlreadyInitiated();
  error NotTheTokenOwner();
  error CannotUpgradeToAnOlderVersion();
  error UntrustedImplementation();
  error NotAvailableIfTokenIdsAreNotProgressive();
  error InvalidTokenId();
  error NftNotInitiated();
  error InvalidMaxTokenId();
  error InvalidIndex();

  function nftConf() external view returns (NftConf memory);

  function managerHistory(uint256 index) external view returns (ManagerHistory memory);

  function setMaxTokenId(uint112 maxTokenId_) external;

  function allowUntrustedTransfers() external view returns (bool);

  // @dev This function will initialize the nft.
  function init(
    address managerAddress_,
    bool progressiveTokenIds_,
    bool allowUntrustedTransfers_,
    uint112 nextTokenId_,
    uint112 maxTokenId_
  ) external;

  function defaultManagerImplementation(uint256 _tokenId) external view returns (address);

  function upgradeDefaultManager(address payable newManagerProxy) external;

  // @dev This function will return the address of the manager for tokenId.
  // @param tokenId The id of the token.
  function managerOf(uint256 tokenId) external view returns (address);

  // called by the manager only
  function deployPlugin(
    address pluginImplementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) external returns (address);

  function isDeployed(
    address implementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) external view returns (bool);
}
