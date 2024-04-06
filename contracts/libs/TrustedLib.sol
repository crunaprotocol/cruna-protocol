// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title TrustedLib
 */
library TrustedLib {
  /**
   * @notice Returns if untrusted implementations are allowed
   * @dev When on those chain, it is possible to skip the requirement that an implementation is trusted.
   *
   * To keep this function efficient, we support only the most popular chains at the moment.
   *
   * - Goerli
   * - BNB Testnet
   * - Chronos Testnet
   * - Fantom
   * - Avalance Fuji
   * - Celo Alfajores
   * - Gnosis Testnet
   * - Polygon Mumbai
   * - Arbitrum Testnet
   * - Sepolia
   * - Base Sepolia
   */
  function areUntrustedImplementationsAllowed() internal view returns (bool) {
    uint256 chainId = block.chainid;
    return (chainId == 5 || // goerli
      chainId == 97 || // bsc testnet
      chainId == 338 || // chronos testnet
      chainId == 4002 || // fantom testnet
      chainId == 10200 || // gnosis testnet
      chainId == 43113 || // avalanche fuji
      chainId == 44787 || // celo alfajores
      chainId == 80001 || // polygon mumbai
      chainId == 84532 || // base sepolia
      chainId == 421614 || // arbitrum testnet
      chainId == 11155111); // sepolia
  }
}
