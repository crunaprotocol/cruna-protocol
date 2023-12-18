const fs = require("fs");
const path = require("path");

const [, , dir] = process.argv;

function findUnusedCustomErrors(contractContent) {
  const errorRegex = /error\s+(\w+)\(\);/g;
  let match;
  let errors = [];
  while ((match = errorRegex.exec(contractContent)) !== null) {
    errors.push(match[1]);
  }
  return errors.filter((error) => !RegExp("revert " + error + "\\(", "g").test(contractContent));
}

const skipFiles = ["CrunaRegistry.sol"];

function analyzeContracts(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  entries.forEach((entry) => {
    if (skipFiles.includes(entry.name)) {
      return;
    }
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      analyzeContracts(fullPath);
    } else if (path.extname(entry.name) === ".sol") {
      const content = fs.readFileSync(fullPath, "utf-8");
      const unusedErrors = findUnusedCustomErrors(content);
      if (unusedErrors.length > 0) {
        console.log(`\nUnused custom errors in:\n  ${fullPath}\n${unusedErrors.join("\n")}`);
        process.exit(1);
      }
    }
  });
}

analyzeContracts(path.resolve(__dirname, "..", dir || "contracts"));
