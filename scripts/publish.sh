#!/usr/bin/env bash

SCRIPT_DIR=$(dirname "$0")
VERSION=$($SCRIPT_DIR/get-package-version.js)

cp README.md contracts/README.md
cd contracts

if [[ $VERSION == *"-alpha"* ]]; then
  echo "Publishing alpha version $VERSION"
  npm publish --tag alpha
elif [[ $VERSION == *"-beta"* ]]; then
  echo "Publishing beta version $VERSION"
  npm publish --tag beta
else
  echo "Publishing stable version $VERSION"
  npm publish
fi

rm README.md
cd ..
