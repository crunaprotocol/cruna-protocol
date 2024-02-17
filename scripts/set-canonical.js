#!/usr/bin/env node

const path = require("path");
const fs = require("fs-extra");

const dir = path.resolve(__dirname, "../canonical-addresses");
const dest = path.resolve(__dirname, "../contracts/utils/CanonicalAddresses.sol");
const mocks = path.resolve(__dirname, "../contracts/mocks/coverage");

// the scripts that requires this one should set the env variable CHAIN_ID
let chainId = parseInt(process.env.CHAIN_ID || "0");
fs.removeSync(mocks);

if (process.env.IS_COVERAGE) {
  fs.copySync(path.join(dir, "hardhat.sol"), dest);
  fs.copySync(path.join(dir, "coverage"), mocks);
} else if (process.env.NODE_ENV === "test" || chainId === 1337) {
  fs.copySync(path.join(dir, "hardhat.sol"), dest);
} else if ([44787, 80001].includes(chainId)) {
  fs.copySync(path.join(dir, "testnet.sol"), dest);
} else {
  fs.copySync(path.join(dir, "mainnet.sol"), dest);
}
