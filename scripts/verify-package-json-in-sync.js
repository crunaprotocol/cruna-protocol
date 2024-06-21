#!/usr/bin/env node
const fs = require("fs-extra");
const path = require("path");
const pkg = require("../package.json");
const pkgc = require("../contracts/package.json");

if (pkg.version !== pkgc.version) {
  pkgc.version = pkg.version;
  pkgc.dependencies = pkg.dependencies;
  fs.writeFileSync(path.resolve(__dirname, "../contracts/package.json"), JSON.stringify(pkgc, null, 2));
}
