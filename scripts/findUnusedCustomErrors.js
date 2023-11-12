const fs = require("fs");
const path = require("path");

const CONTRACTS_DIR = path.resolve(__dirname, "../contracts/protected");

function findUnusedCustomErrors(contractContent) {
  const errorRegex = /error\s+(\w+)\(\);/g;
  let match;
  let errors = [];

  while ((match = errorRegex.exec(contractContent)) !== null) {
    errors.push(match[1]);
  }

  return errors.filter((error) => !RegExp("revert " + error + "\\(", "g").test(contractContent));
}

function analyzeContracts(dir) {
  const files = fs.readdirSync(dir);
  files.forEach((file) => {
    if (path.extname(file) === ".sol") {
      const content = fs.readFileSync(path.join(dir, file), "utf-8");
      const unusedErrors = findUnusedCustomErrors(content);
      if (unusedErrors.length > 0) {
        console.log(`\nIn file ${file}, unused custom errors:\n\n${unusedErrors.join("\n")}`);
      }
    }
  });
}

analyzeContracts(CONTRACTS_DIR);
