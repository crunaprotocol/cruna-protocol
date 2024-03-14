// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Author : Francesco Sullo <francesco@sullo.co>

interface IVaultFactory {
  // @notice Emitted when a price is set
  // @param price the new price

  event PriceSet(uint256 price);

  event StableCoinSet(address indexed stableCoin, bool active);

  // @notice Set the price
  // @param price the new price
  //   The price is expressed in points, 1 point = 0.01 USD

  function setPrice(uint256 price) external;

  function getPrice() external view returns (uint256);

  function finalPrice(address stableCoin) external view returns (uint256);

  function setDiscount(uint256 discount) external;

  // @notice Activate/deactivate a stable coin
  // @param stableCoin the payment token to use for the purchase
  // @param active true to activate, false to deactivate

  function setStableCoin(address stableCoin, bool active) external;

  // @notice Allow people to buy vaults
  // @param stableCoin the payment token to use for the purchase
  // @param amount number to buy

  function buyVaults(address stableCoin, uint256 amount) external;

  function buyVaultsBatch(address stableCoin, address[] memory tos, uint256[] memory amounts) external;

  // @notice Given a payment token, transfers amount or full balance from proceeds to an address
  // @param beneficiary address of the beneficiary
  // @param stableCoin the payment token to use for the transfer
  // @param amount number to transfer

  function withdrawProceeds(address beneficiary, address stableCoin, uint256 amount) external;
}
