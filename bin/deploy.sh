#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

#npm run clean

if [[ "$2" == "localhost" ]]; then
  SKIP_CRYPTOENV=true npx hardhat run scripts/deploy-$1.js --network $2
else
  scripts/check-hardhat-console.js && npx hardhat run scripts/deploy-$1.js --network $2
fi

