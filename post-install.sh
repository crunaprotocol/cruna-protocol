#!/usr/bin/env bash

if [[ -d "/home/ubuntu/" ]]; then
  exit 0
fi

EXISTS=

if [[ -f "./.husky/pre-commit" ]]; then
  EXISTS=`cat ./.husky/pre-commit | grep "npm run lint"`
fi

if [[ "$EXISTS" == "" ]]; then
    npx mrm@2 lint-staged
    npx husky-init
    pnpm i -D pretty-quick
    npx husky set .husky/pre-commit "npm run lint && bin/get-coverage.sh && bin/export.sh && git add -A"
fi

node ./scripts/conditional-symlink.js
