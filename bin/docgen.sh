#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

# Backup the contracts
rm -rf ./backup_contracts
cp -r ./contracts ./backup_contracts

# Resolve the dependencies
node scripts/docs/resolve-docs-references.js

exit 0

# Compiles the new contracts to validate them
npm run compile
compile_status=$?

# Lint the new contracts
npm run lint:sol
lint_status=$?

# Check if both commands were successful
if [ $compile_status -eq 0 ] && [ $lint_status -eq 0 ]; then
    # If successful, produce the docs
    SKIP_CRYPTOENV=true npx hardhat docgen
    node scripts/docs/gen-index.js
else
    echo "Compilation or linting failed, skipping documentation generation."
fi

# Revert the contracts
rm -rf ./contracts
mv ./backup_contracts ./contracts

echo "Process completed."

#rm -rf ./contracts && cp -r ./backup_contracts ./contracts

