#!/usr/bin/env bash

SCRIPT_DIR=$(dirname "$0")
VERSION=$($SCRIPT_DIR/get-package-version.js)
echo $VERSION

cp README.md contracts/README.md
cd contracts

if [[ $VERSION == *"-alpha"* ]]; then
  npm publish --tag alpha
elif [[ $VERSION == *"-beta"* ]]; then
  npm publish --tag beta
else
  npm publish
fi

rm README.md
cd ..
