#!/usr/bin/env bash

if [[ -d "/home/ubuntu/" ]]; then
  exit 0
fi

EXISTS=

if [[ -f "./.husky/pre-commit" ]]; then
  EXISTS=`cat ./.husky/pre-commit | grep "npm run lint"`
fi

if [[ "$EXISTS" == "" ]]; then
    npx husky-init
    pnpm i -D pretty-quick
    npx husky set .husky/pre-commit "# to skip it call git commit with HUSKY=0 git commit ...
if [[ \"\$HUSKY\" != \"0\" ]]; then
 npm run lint && bin/get-coverage.sh && bin/export.sh && bin/docgen.sh && git add -A
fi
"
fi
