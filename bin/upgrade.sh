#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

npm run clean
npx hardhat compile

scripts/check-hardhat-console.js && CONTRACT=$1 GAS_LIMIT=$3 npx hardhat run scripts/upgrade.js --network $2
