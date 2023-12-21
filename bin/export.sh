#!/usr/bin/env bash

(
  root_dir=$(dirname $(realpath $(dirname "$0")))
  # if not run from the root, we cd into the root
  cd $root_dir

  SKIP_CRYPTOENV=true

  if [[ "$SKIP_COMPILE" == "" ]]; then
    npm run clean
    NODE_ENV=test npx hardhat compile
  fi

  node scripts/exportABIs.js
)
