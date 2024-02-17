#!/usr/bin/env node

const path = require("path");
const fs = require("fs-extra");
let pkg = require("../package.json");

pkg.name = "@cruna/cruna-protocol-testnet";

fs.writeFileSync(path.resolve(__dirname, "../package.json"), JSON.stringify(pkg, null, 2));

pkg = require("../contracts/package.json");

pkg.name = "@cruna/cruna-protocol-testnet";

fs.writeFileSync(path.resolve(__dirname, "../contracts/package.json"), JSON.stringify(pkg, null, 2));
