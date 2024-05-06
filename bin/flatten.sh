#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

if [[ ! -d "flattened" ]]; then
  mkdir flattened
fi
FOLDER=""
if [[ "$2" != "" ]]; then
  FOLDER=$2/
fi

cp libs-canonical/not-localhost/GuardianInstance.sol contracts/libs/.

NODE_ENV=test npx hardhat flatten contracts/$FOLDER$1.sol > flattened/$1-flattened.sol
scripts/clean-licenses-in-flattened.js $1

cp libs-canonical/localhost/GuardianInstance.sol contracts/libs/.
