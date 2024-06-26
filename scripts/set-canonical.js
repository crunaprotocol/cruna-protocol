#!/usr/bin/env node

const path = require("path");
const fs = require("fs-extra");
const deployUtils = new require("eth-deploy-utils");

const dir = path.resolve(__dirname, "../libs-canonical");
const dest = path.resolve(__dirname, "../contracts/libs/GuardianInstance.sol");

// any scripts that requires this one should set the env variable CHAIN_ID
let chainId = process.env.CHAIN_ID || "0";

if (process.env.NODE_ENV === "test" || chainId === "1337") {
  fs.copySync(path.join(dir, "localhost/GuardianInstance.sol"), dest);
} else {
  fs.copySync(path.join(dir, "not-localhost/GuardianInstance.sol"), dest);
}
