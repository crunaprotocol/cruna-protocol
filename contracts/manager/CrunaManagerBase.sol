// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {IBoundContract} from "../utils/IBoundContract.sol";
import {ICrunaRegistry} from "../utils/CrunaRegistry.sol";
import {ICrunaGuardian} from "../utils/ICrunaGuardian.sol";
import {IVersioned} from "../utils/IVersioned.sol";

import {ICrunaManagerBase, IVault, IImplementation} from "./ICrunaManagerBase.sol";

//import {console} from "hardhat/console.sol";

/**
  @title CrunaManagerBase.sol
  @dev Base contract for managers and plugins
*/
abstract contract CrunaManagerBase is Context, IBoundContract, IVersioned, ICrunaManagerBase {
  error NotTheTokenOwner();
  error UntrustedImplementation();
  error InvalidVersion();
  error PluginRequiresUpdatedManager(uint256 requiredVersion);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  uint256 public currentVersion;

  constructor() {
    currentVersion = version();
  }

  function version() public pure virtual returns (uint256) {
    return 1e6;
  }

  function nameId() public virtual returns (bytes4);

  function guardian() public view virtual returns (ICrunaGuardian) {
    return vault().guardian();
  }

  function registry() public view virtual returns (ICrunaRegistry) {
    return vault().registry();
  }

  function vault() public view virtual returns (IVault) {
    return IVault(tokenAddress());
  }

  modifier onlyTokenOwner() {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  function token() public view virtual override returns (uint256, address, uint256) {
    return ERC6551AccountLib.token();
  }

  function owner() public view virtual returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = token();
    if (chainId != block.chainid) return address(0);
    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  function tokenAddress() public view virtual returns (address) {
    (, address tokenContract_, ) = token();
    return tokenContract_;
  }

  function tokenId() public view virtual returns (uint256) {
    (, , uint256 tokenId_) = token();
    return tokenId_;
  }

  function combineBytes4(bytes4 a, bytes4 b) public pure returns (bytes32) {
    return (bytes32(a) >> 192) | (bytes32(b) >> 224);
  }

  function _stringToBytes4(string memory str) internal pure returns (bytes4) {
    return bytes4(keccak256(abi.encodePacked(str)));
  }

  // @dev Upgrade the implementation of the manager/plugin
  //   Notice that the owner can upgrade active or disable plugins
  //   so that, if a plugin is compromised, the user can disable it,
  //   wait for a new trusted implementation and upgrade it.
  function upgrade(address implementation_) external virtual {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    uint256 requires = guardian().trustedImplementation(nameId(), implementation_);
    if (requires == 0) revert UntrustedImplementation();
    IImplementation impl = IImplementation(implementation_);
    uint256 _version = impl.version();
    if (_version <= currentVersion) revert InvalidVersion();
    if (impl.nameId() != _stringToBytes4("Manager")) {
      IImplementation manager = IImplementation(vault().managerOf(tokenId()));
      if (manager.version() < requires) revert PluginRequiresUpdatedManager(requires);
    }
    currentVersion = _version;
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  function getImplementation() external view returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
