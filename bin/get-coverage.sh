#!/usr/bin/env bash

echo "Generating coverage report"
npm run coverage > tmp/coverage.report
node scripts/insert-coverage.js
echo "Done"
