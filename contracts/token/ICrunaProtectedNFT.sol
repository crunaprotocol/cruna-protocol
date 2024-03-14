// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IManagedNFT} from "./IManagedNFT.sol";

/**
 * @title ICrunaProtectedNFT
 * @author Francesco Sullo <francesco@sullo.co>
 */
interface ICrunaProtectedNFT is IManagedNFT, IERC721 {
  /**
   * @dev Optimized configuration structure for the generic NFT
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

  /**
   * @dev Manager history structure
   * Elements:
   * - firstTokenId is the first tokenId using a specific manager.
   * - lastTokenId is the last tokenId managed by the same manager.
   * - managerAddress is the address of the manager.
   */
  struct ManagerHistory {
    uint112 firstTokenId;
    uint112 lastTokenId;
    address managerAddress;
  }

  // events

  /**
   * @dev Emitted when the default manager is upgraded
   * @param newManagerProxy The address of the new manager proxy
   */
  event DefaultManagerUpgrade(address indexed newManagerProxy);

  /**
   * @dev Emitted when the maxTokenId is changed
   * @param maxTokenId The new maxTokenId
   */
  event MaxTokenIdChange(uint112 maxTokenId);

  // errors

  /// @dev Error returned when the caller is not the token owner
  error NotTransferable();

  /// @dev Error returned when the caller is not the manager
  error NotTheManager();

  /// @dev Error returned when the caller is not the token owner
  error ZeroAddress();

  /// @dev Error returned when the token is already initiated
  error AlreadyInitiated();

  /// @dev Error returned when the caller is not the token owner
  error NotTheTokenOwner();

  /// @dev Error returned when trying to upgrade to an older version
  error CannotUpgradeToAnOlderVersion();

  /// @dev Error returned when the new implementation of the manager is not trusted
  error UntrustedImplementation(address implementation);

  /// @dev Error returned when trying to call a function that requires progressive token ids
  error NotAvailableIfTokenIdsAreNotProgressive();

  /// @dev Error returned when the token id is invalid
  error InvalidTokenId();

  /// @dev Error returned when the NFT is not initiated
  error NftNotInitiated();

  /// @dev Error returned when trying too set an invalid MaxTokenId
  error InvalidMaxTokenId();

  /// @dev Error returned when an index is invalid
  error InvalidIndex();

  // views

  /// @dev Returns the configuration of the NFT
  function nftConf() external view returns (NftConf memory);

  /**
   * @dev Returns the manager history for a specific index
   * @param index The index
   */
  function managerHistory(uint256 index) external view returns (ManagerHistory memory);

  /**
   * @dev set the maximum tokenId that can be minted
   * @param maxTokenId_ The new maxTokenId
   */
  function setMaxTokenId(uint112 maxTokenId_) external;

  /**
   * @dev Returns true if the token allows untrusted plugins to transfer the tokens
   * This is usually set to true for testnets and false for mainnets
   */
  function allowUntrustedTransfers() external view returns (bool);

  /**
   * @dev Initialize the NFT
   * @param managerAddress_ The address of the manager
   * @param progressiveTokenIds_ If true, the tokenIds will be progressive
   * @param allowUntrustedTransfers_ If true, the token will allow untrusted plugins to transfer the tokens
   * @param nextTokenId_ The next tokenId to be used
   * @param maxTokenId_ The maximum tokenId that can be minted (it can be 0 if no upper limit)
   */
  function init(
    address managerAddress_,
    bool progressiveTokenIds_,
    bool allowUntrustedTransfers_,
    uint112 nextTokenId_,
    uint112 maxTokenId_
  ) external;

  /**
   * @dev Returns the address of the default implementation of the manager for a tokenId
   * @param _tokenId The tokenId
   */
  function defaultManagerImplementation(uint256 _tokenId) external view returns (address);

  /**
   * @dev Upgrade the default manager for any following tokenId
   * @param newManagerProxy The address of the new manager proxy
   */
  function upgradeDefaultManager(address payable newManagerProxy) external;

  /**
   * @dev Return the address of the manager of a tokenId
   * @param tokenId The id of the token.
   */
  function managerOf(uint256 tokenId) external view returns (address);

  /**
   * @dev Deploys a plugin
   * @param pluginImplementation The address of the plugin implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @param isERC6551Account Specifies the registry to use
   * True if the tokenId must be deployed via ERC6551Registry,
   * false, it must be deployed via CrunaRegistry
   */
  function deployPlugin(
    address pluginImplementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) external returns (address);

  /**
   * @dev Returns if a plugin is deployed
   * @param implementation The address of the plugin implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @param isERC6551Account Specifies the registry to use
   * True if the tokenId was deployed via ERC6551Registry,
   * false, it was deployed via CrunaRegistry
   */
  function isDeployed(
    address implementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) external view returns (bool);
}
