// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Author : Francesco Sullo <francesco@sullo.co>

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Initializable, UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {VaultMock} from "../VaultMock.sol";
import {IVaultFactoryMock} from "./IVaultFactoryMock.sol";
import {IVersioned} from "../../utils/IVersioned.sol";

//import {console} from "hardhat/console.sol";

contract VaultFactoryMock is
  IVaultFactoryMock,
  IVersioned,
  Initializable,
  PausableUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  UUPSUpgradeable
{
  error ZeroAddress();
  error InsufficientFunds();
  error UnsupportedStableCoin();
  error TransferFailed();
  error InvalidArguments();
  error InvalidDiscount();

  VaultMock public vault;
  uint256 public price;
  mapping(address => bool) public stableCoins;
  uint256 public discount;
  address[] private _stableCoins;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address vault_, address owner_) public initializer {
    __Ownable_init(owner_);
    __UUPSUpgradeable_init();
    vault = VaultMock(vault_);
  }

  function version() public pure virtual returns (uint256) {
    return 1e6;
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  // @notice The price is in points, so that 1 point = 0.01 USD
  function setPrice(uint256 price_) external virtual override onlyOwner {
    // it is owner's responsibility to set a reasonable price
    price = price_;
    emit PriceSet(price);
  }

  function setStableCoin(address stableCoin, bool active) external virtual override onlyOwner {
    if (active) {
      // We check if less than 6 because TetherUSD has 6 decimals
      // It should revert if the stableCoin is not an ERC20
      if (ERC20(stableCoin).decimals() < 6) {
        revert UnsupportedStableCoin();
      }
      if (!stableCoins[stableCoin]) {
        stableCoins[stableCoin] = true;
        _stableCoins.push(stableCoin);
        emit StableCoinSet(stableCoin, active);
      }
    } else if (stableCoins[stableCoin]) {
      delete stableCoins[stableCoin];
      // no risk of going out of cash because the factory will support just a couple of stable coins
      for (uint256 i = 0; i < _stableCoins.length; i++) {
        if (_stableCoins[i] == stableCoin) {
          _stableCoins[i] = _stableCoins[_stableCoins.length - 1];
          _stableCoins.pop();
          break;
        }
      }
      emit StableCoinSet(stableCoin, active);
    }
  }

  function setDiscount(uint256 discount_) external virtual override onlyOwner {
    if (discount > price) revert InvalidDiscount();
    discount = discount_;
  }

  function finalPrice(address stableCoin) public view virtual override returns (uint256) {
    return (getPrice() * (10 ** ERC20(stableCoin).decimals())) / 100;
  }

  function getPrice() public view virtual override returns (uint256) {
    return price - discount;
  }

  function buyVaults(address stableCoin, uint256 amount, bool alsoInit) external virtual override whenNotPaused nonReentrant {
    uint256 payment = finalPrice(stableCoin) * amount;
    if (payment > ERC20(stableCoin).balanceOf(_msgSender())) revert InsufficientFunds();
    vault.safeMintAndActivate(_msgSender(), alsoInit, amount);
    // we manage only trusted stable coins, so no risk of reentrancy
    if (!ERC20(stableCoin).transferFrom(_msgSender(), address(this), payment)) revert TransferFailed();
  }

  function buyVaultsBatch(
    address stableCoin,
    address[] memory tos,
    uint256[] memory amounts,
    bool alsoInit
  ) external virtual override whenNotPaused nonReentrant {
    if (tos.length != amounts.length) revert InvalidArguments();
    uint256 amount = 0;
    for (uint256 i = 0; i < tos.length; i++) {
      if (tos[i] == address(0)) {
        revert ZeroAddress();
      }
      amount += amounts[i];
    }
    uint256 payment = finalPrice(stableCoin) * amount;
    if (payment > ERC20(stableCoin).balanceOf(_msgSender())) revert InsufficientFunds();
    for (uint256 i = 0; i < tos.length; i++) {
      if (amounts[i] > 0) {
        vault.safeMintAndActivate(tos[i], alsoInit, amounts[i]);
      }
    }
    // we manage only trusted stable coins, so no risk of reentrancy
    if (!ERC20(stableCoin).transferFrom(_msgSender(), address(this), payment)) revert TransferFailed();
  }

  function withdrawProceeds(address beneficiary, address stableCoin, uint256 amount) external virtual override onlyOwner {
    uint256 balance = ERC20(stableCoin).balanceOf(address(this));
    if (amount == 0) {
      amount = balance;
    }
    if (amount > balance) revert InsufficientFunds();
    if (!ERC20(stableCoin).transfer(beneficiary, amount)) revert TransferFailed();
  }

  function getStableCoins() external view virtual returns (address[] memory) {
    return _stableCoins;
  }
}
