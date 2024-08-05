#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

if [[ $NO_CHECK == "" ]]; then
  # Check if the current branch is 'main'
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  if [ "$current_branch" != "main" ]; then
      echo "Error: Not on the 'main' branch. Skip with NO_CHECK=1 if you want to publish anyway."
      exit 1
  fi

  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD --; then
      echo "Error: There are uncommitted changes. Skip with NO_CHECK=1 if you want to publish anyway."
      exit 1
  fi
fi

# we call the script explicitly via node because if not, if the file is
# missing, the version will just be empty and no error is returned
version=$(node scripts/get-package-version.js)

if [[ $version == "" ]]; then
  echo "Error: Could not get the package version."
  exit 1
fi

cp libs-canonical/not-localhost/GuardianInstance.sol contracts/libs/.

cp README.md contracts/README.md
cd contracts

if [[ $version =~ -([a-zA-Z]+) ]]; then
  tag=${BASH_REMATCH[1]}
  echo "Publishing $tag version $version"
  npm publish --tag $tag
else
  echo "Publishing stable version $version"
  npm publish NO_CHECK=1
fi

rm README.md

cd ..
cp libs-canonical/localhost/GuardianInstance.sol contracts/libs/.
