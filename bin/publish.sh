#!/usr/bin/env bash

# Check if the current branch is 'main'
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main" ]; then
    echo "Error: Not on the 'main' branch."
    exit 1
fi

 Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Error: There are uncommitted changes."
    exit 1
fi

if [ -d "./bin" ]; then
  echo "Task started..."
else
  echo "Error: You must run this script from the root of the repository."
  exit 1
fi

bin_dir=$(dirname "$0")
# we call the script explicitly via node because if not, if the file is
# missing, the version will just be empty and no error is returned
version=$(node $bin_dir/../scripts/get-package-version.js)

if [[ $version == "" ]]; then
  echo "Error: Could not get the package version."
  exit 1
fi

cp README.md contracts/README.md
cd contracts

echo "Publishing contracts version $version"
exit 0
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
