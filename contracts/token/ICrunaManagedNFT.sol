// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// Author: Francesco Sullo <francesco@sullo.co>
interface ICrunaManagedNFT is IERC721 {
  event ManagedTransfer(bytes4 indexed pluginNameId, uint256 indexed tokenId);
  event DefaultManagerUpgrade(address newManagerProxy);

  struct ManagerHistory {
    address managerAddress;
    uint256 firstTokenId;
    uint256 lastTokenId;
  }

  // @dev Allow a plugin to transfer the token
  // @param pluginNameId The hash of the plugin name.
  // @param tokenId The id of the token.
  // @param to The address of the recipient.
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external;

  function setMaxTokenId(uint256 maxTokenId_) external;

  // @dev This function will initialize the contract.
  // @param managerProxy_ The address of the manager proxy.
  // @param firstTokenId_ The first tokenId to be used. Notice that in multi-chain scenarios,
  //   the same tokenId can be used on different chains, so it's important to avoid collisions.
  //   A good practice is to use the chainId as a prefix. For example, the first token on Polygon
  //   could be 137000001, while the first token on BSC could be 56000001.
  function init(address managerProxy_, uint256 firstTokenId_, bool deployedToProduction_) external;

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
}
