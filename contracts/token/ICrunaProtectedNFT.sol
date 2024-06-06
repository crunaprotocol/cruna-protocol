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
   * @notice Optimized configuration structure for the generic NFT
   *
   * TokenIds are uint96 for optimization purposes. In particular, having the tokenId as a uint96 allows
   * to encode the tokenId in the first 12 bytes of the storage slot, leaving the last 20 bytes for the token address
   * That allows services and other tools to save storage because tokenAddress + tokenId will take a single word.
   * For example, tokenAddress and tokenId can be encoded as
   * uint256 tokenAddressAndTokenId = uint256(tokenAddress) << 96 | tokenId;
   *
   * Elements:
   * - progressiveTokenIds is used to allow the upgrade of the default manager implementation. It is used to assure that the manager can be upgraded in a safe way.
   * - nextTokenId is the next tokenId to be used. It is used to mint new tokens if progressiveTokenIds is true.
   * - maxTokenId is the maximum tokenId that can be minted. It is used to limit the minting of new tokens.
   * - managerHistoryLength is the length of the manager history.
   */
  struct NftConf {
    uint96 nextTokenId;
    uint96 maxTokenId;
    bool progressiveTokenIds;
    uint8 managerHistoryLength;
    // for future changes
    uint8 unusedField;
  }

  /**
   * @notice Manager history structure
   * Elements:
   * - firstTokenId is the first tokenId using a specific manager.
   * - lastTokenId is the last tokenId managed by the same manager.
   * - managerAddress is the address of the manager.
   */
  struct ManagerHistory {
    uint96 firstTokenId;
    uint96 lastTokenId;
    address managerAddress;
  }

  // events

  event ManagedActivatedFor(uint256 tokenId, address manager);

  /**
   * @notice Emitted when the default manager is upgraded
   * @param newManagerProxy The address of the new manager proxy
   */
  event DefaultManagerUpgrade(address indexed newManagerProxy);

  /**
   * @notice Emitted when the maxTokenId is changed
   * @param maxTokenId The new maxTokenId
   */
  event MaxTokenIdChange(uint96 maxTokenId);

  // errors

  /**
   * @notice Error returned when the caller is not the token owner
   */
  error NotTransferable();

  /**
   * @notice Error returned when the caller is not the manager
   */
  error NotTheManager();

  /**
   * @notice Error returned when the caller is not the token owner
   */
  error ZeroAddress();

  /**
   * @notice Error returned when the token is already initiated
   */
  error AlreadyInitiated();

  /**
   * @notice Error returned when the caller is not the token owner
   */
  error NotTheTokenOwner();

  /**
   * @notice Error returned when trying to upgrade to an older version
   */
  error CannotUpgradeToAnOlderVersion();

  /**
   * @notice Error returned when the new implementation of the manager is not trusted
   */
  error UntrustedImplementation(address implementation);

  /**
   * @notice Error returned when trying to call a function that requires progressive token ids
   */
  error NotAvailableIfTokenIdsAreNotProgressive();

  /**
   * @notice Error returned when the token id is invalid
   */
  error InvalidTokenId();

  /**
   * @notice Error returned when the NFT is not initiated
   */
  error NftNotInitiated();

  /**
   * @notice Error returned when trying too set an invalid MaxTokenId
   */
  error InvalidMaxTokenId();

  /**
   * @notice Error returned when an index is invalid
   */
  error InvalidIndex();

  /**
   * @notice Error returned if the sender is neither the manager nor the token owner
   */
  error OnlyTokenOwnerOrManager();

  /**
   * @notice Error returned when the token owner tries to deploy a service that must be managed
   */
  error ManagedService();

  /**
   * @notice Error returned when the token owner tries to activate and already activated token
   */
  error AlreadyActivated(uint256 tokenId);

  // views

  /**
   * @notice Returns the configuration of the NFT
   */
  function nftConf() external view returns (NftConf memory);

  /**
   * @notice Returns the manager history for a specific index
   * @param index The index
   */
  function managerHistory(uint256 index) external view returns (ManagerHistory memory);

  /**
   * @notice set the maximum tokenId that can be minted
   * @param maxTokenId_ The new maxTokenId
   */
  function setMaxTokenId(uint96 maxTokenId_) external;

  /**
   * @notice Initialize the NFT
   * @param managerAddress_ The address of the manager
   * @param progressiveTokenIds_ If true, the tokenIds will be progressive
   * @param nextTokenId_ The next tokenId to be used.
   * If progressiveTokenIds_ == true and the project must reserve some tokens to
   * special addresses, community, etc. You set the nextTokenId_ to the first not reserved token.
   * Be careful, your function minting by tokenId MUST check that the tokenId is
   * not higher than nextTokenId. If not, when trying to mint tokens by amount, as soon as
   * nextTokenId reaches the minted tokenId, the function will revert, blocking any future minting.
   * If your code may risk so, set a function that allow you to correct the nextTokenId to skip
   * the token minted by mistake.
   * @param maxTokenId_ The maximum tokenId that can be minted (it can be 0 if no upper limit)
   */
  function init(address managerAddress_, bool progressiveTokenIds_, uint96 nextTokenId_, uint96 maxTokenId_) external;

  /**
   * @notice Returns the address of the default implementation of the manager for a tokenId
   * @param _tokenId The tokenId
   */
  function defaultManagerImplementation(uint256 _tokenId) external view returns (address);

  /**
   * @notice Upgrade the default manager for any following tokenId
   * @param newManagerProxy The address of the new manager proxy
   */
  function upgradeDefaultManager(address payable newManagerProxy) external;

  /**
   * @notice Return the address of the manager of a tokenId
   * @param tokenId The id of the token.
   */
  function managerOf(uint256 tokenId) external view returns (address);

  /**
   * @notice Returns the address of a deployed manager or plugin
   * @param key_ The encoded key of the service
   * @param tokenId The tokenId
   * @param isERC6551Account Specifies the registry to use
   * True if the tokenId was deployed via ERC6551Registry,
   * false, it was deployed via ERC7656Registry
   * @return The address of the deployed manager or plugin
   */
  function addressOfDeployed(bytes32 key_, uint256 tokenId, bool isERC6551Account) external view returns (address);

  /**
   * @notice Deploys an unmanaged service
   * @param key_ The encoded key of the service
   * @param tokenId The tokenId
   * @param isERC6551Account Specifies the registry to use
   * True if the tokenId must be deployed via ERC6551Registry,
   * false, it must be deployed via ERC7656Registry
   */
  function plug(bytes32 key_, uint256 tokenId, bool isERC6551Account, bytes memory data) external payable;

  /**
   * @notice Returns if a plugin is deployed
   * @param key_ The encoded key of the service
   * @param tokenId The tokenId
   * @param isERC6551Account Specifies the registry to use
   * True if the tokenId was deployed via ERC6551Registry,
   * false, it was deployed via ERC7656Registry
   */
  function isDeployed(bytes32 key_, uint256 tokenId, bool isERC6551Account) external view returns (bool);
}
