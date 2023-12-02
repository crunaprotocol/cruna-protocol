#!/usr/bin/env bash

# Check if the current branch is 'main'
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main" ]; then
    echo "Error: Not on the 'main' branch."
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Error: There are uncommitted changes."
    exit 1
fi

if [ -d "./bin" ]; then
  echo "Publishing started..."
else
  echo "You must run this script from the root of the repository."
  exit 1
fi

script_dir=$(dirname "$0")
version=$($script_dir/get-package-version.js)

cp README.md contracts/README.md
cd contracts

if [[ $version == *"-alpha"* ]]; then
  echo "Publishing alpha version $version"
  npm publish --tag alpha
elif [[ $version == *"-beta"* ]]; then
  echo "Publishing beta version $version"
  npm publish --tag beta
else
  echo "Publishing stable version $version"
  npm publish
fi

rm README.md
cd ..
