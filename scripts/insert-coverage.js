const path = require("path");
const fs = require("fs");
// eslint-disable-next-line node/no-unpublished-require

function decolorize(str) {
  // eslint-disable-next-line no-control-regex
  return str.replace(/\x1b\[[0-9;]*m/g, "");
}

let coverage = fs.readFileSync(path.resolve(__dirname, "../tmp/coverage.report"), "utf8").split("\n");

let result = [];
for (let row of coverage) {
  row = decolorize(row);

  if (/ {2}\d+ failing/.test(row)) {
    // eslint-disable-next-line no-process-exit
    process.exit(1);
  }

  if (result[0]) {
    if (result[2] && !row) {
      break;
    }
    row = row.replace(/\|[^|]+\|$/, "");
    result.push(row);
  }
  if (/ {2}\d+ passing/.test(row)) {
    row = row.replace(/(\d+ passing) \([^)]+\)/g, "$1");
    result.push(row);
  }
}

let text = "## Test coverage";

coverage = result.join("\n");

let p = path.resolve(__dirname, "../COVERAGE.md");

let readCoverage = fs.readFileSync(p, "utf8");

let coverageSection = readCoverage.split("```");

coverageSection[1] = `\n${coverage}\n`;

readCoverage = `${coverageSection.join("```")}`;

fs.writeFileSync(p, readCoverage);
