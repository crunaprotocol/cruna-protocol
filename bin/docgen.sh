#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

rm -rf ./backup_contracts
rm -rf ./tmp/resolved-contracts
rm -rf ./docs/*

# Backup the contracts
cp -r ./contracts ./backup_contracts

# Resolve the dependencies
node scripts/docs/resolve-docs-references.js

cp -r contracts ./tmp/resolved-contracts

npm run compile
compile_status=$?

npm run lint:sol
lint_status=$?

# Check if both commands were successful
if [ $compile_status -eq 0 ] && [ $lint_status -eq 0 ]; then
    # If successful, produce the docs
    SKIP_CRYPTOENV=true npx hardhat docgen
    node scripts/docs/gen-index.js
    echo "Process completed."
else
    echo "Compilation or linting failed, skipping documentation generation."
fi

# Revert the contracts
rm -rf ./contracts
mv ./backup_contracts ./contracts


#rm -rf ./contracts && cp -r ./backup_contracts ./contracts

