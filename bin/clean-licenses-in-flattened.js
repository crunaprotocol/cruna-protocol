#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const ethers = require("ethers");

const [, , contract] = process.argv;
const fn = path.resolve(__dirname, "../flattened", `${contract}-flattened.sol`);
const flattened =
  fs.readFileSync(fn, "utf8") +
  `
// Flattened on ${new Date().toISOString()}
`;

function removeAndCompact(contents) {
  // Remove single-line comments
  const singleLineComments = /\/\/.*$/gm;
  contents = contents.replace(singleLineComments, "");

  // Remove multi-line comments
  const multiLineComments = /\/\*[\s\S]*?\*\//gm;
  contents = contents.replace(multiLineComments, "");

  // Remove new lines and extra spaces
  const newLines = /\s*[\r\n]+\s*/g;
  contents = contents.replace(newLines, " ");

  // Remove extra spaces between words
  const extraSpaces = / +/g;
  contents = contents.replace(extraSpaces, " ");

  // Remove space before and after curly braces
  const spacesAroundBraces = /\s*([{}])\s*/g;
  contents = contents.replace(spacesAroundBraces, "$1");

  // Remove space before and after parentheses
  const spacesAroundParentheses = /\s*([()])\s*/g;
  contents = contents.replace(spacesAroundParentheses, "$1");

  // Remove space before and after semicolons
  const spacesAroundSemicolons = /\s*;\s*/g;
  contents = contents.replace(spacesAroundSemicolons, ";");

  // Remove space before and after commas
  const spacesAroundCommas = /\s*,\s*/g;
  contents = contents.replace(spacesAroundCommas, ",");
  return contents.trim();
}

const hash = ethers.utils.id(removeAndCompact(flattened)).substring(2, 10);

const nfn = fn.replace(/flattened\.sol$/, `${hash}.sol`);
if (fs.existsSync(nfn)) {
  const prev = fs.readFileSync(nfn, "utf8").split("\n// Flattened on ")[1].split("\n")[0].split("T")[0];
  console.log(`
An identical version of ${contract} has been previously flattened on ${prev}.

`);
} else {
  flattened
    .replace(/SPDX-License-Identifier/, "LICENSE-ID")
    .replace(/SPDX-License-Identifier/g, "License")
    .replace(/LICENSE-ID/, "SPDX-License-Identifier");

  fs.writeFileSync(
    fn.replace(/flattened\.sol$/, `${hash}.sol`),
    flattened
      .replace(/SPDX-License-Identifier/, "LICENSE-ID")
      .replace(/SPDX-License-Identifier/g, "License")
      .replace(/LICENSE-ID/, "SPDX-License-Identifier")
  );

  fs.unlinkSync(fn);
}
