#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

if [[ "$COMPILE" != "" ]]; then
  npm run clean
  npm run compile
fi

# Shift the first argument out, $1 (network), leaving constructor parameters
NETWORK=$1
shift

CONTRACT=$1
shift

base=$(basename "$CONTRACT")
CONTRACT_NAME="${base%.sol}"

# Check if the first constructor parameter is "localhost"
if [[ "$1" == "localhost" ]]; then SKIP=true; fi

# Pass all remaining arguments as constructor parameters
SKIP_CRYPTOENV=$SKIP npx hardhat verify --show-stack-traces --contract contracts/$CONTRACT:$CONTRACT_NAME --network $NETWORK $@
