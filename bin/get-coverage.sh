#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

echo "Generating coverage report" && npm run coverage > tmp/coverage.report && node scripts/insert-coverage.js && echo "Done"
