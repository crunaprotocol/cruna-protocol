#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

cp -r ./contracts ./backup_contracts
node scripts/docs/resolve-docs-references.js
npm run lint:sol
SKIP_CRYPTOENV=true npx hardhat docgen
node scripts/docs/gen-index.js
rm -rf ./contracts
mv ./backup_contracts ./contracts


#rm -rf ./contracts
#cp -r ./backup_contracts ./contracts

