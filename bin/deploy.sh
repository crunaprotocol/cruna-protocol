#!/usr/bin/env bash

#npm run clean

if [[ "$2" == "localhost" ]]; then
  SKIP_CRYPTOENV=true npx hardhat run scripts/deploy-$1.js --network $2
else
  scripts/check-hardhat-console.js && npx hardhat run scripts/deploy-$1.js --network $2
fi

