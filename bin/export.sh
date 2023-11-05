#!/usr/bin/env bash
# must be run from the root

if [[ "$SKIP_COMPILE" == "" ]]; then
  npm run clean
  NODE_ENV=test npx hardhat compile
fi

node scripts/exportABIs.js
cp export/ABIs.json ../cruna-dashboard/src/config/.
cp export/deployed.json ../cruna-dashboard/src/config/.
