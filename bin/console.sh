#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

#npm run clean

if [[ "$1" == "localhost" ]]; then
  SKIP_CRYPTOENV=true npx hardhat run scripts/customConsole.js --network $1
else
  scripts/check-hardhat-console.js && npx hardhat run scripts/customConsole.js --network $1
fi

