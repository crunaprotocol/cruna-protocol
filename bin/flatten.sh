#!/usr/bin/env bash

script_dir=$(dirname "$0")

if [[ ! -d "./flattened" ]]; then
  mkdir flattened
fi
FOLDER=""
if [[ "$2" != "" ]]; then
  FOLDER=$2/
fi
NODE_ENV=test npx hardhat flatten contracts/$FOLDER$1.sol > ./flattened/$1-flattened.sol
# $script_dir/../scripts/clean-licenses-in-flattened.js $1
