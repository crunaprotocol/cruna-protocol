const fs = require("fs");
const path = require("path");

// Function to recursively read through directory and process files
function processDirectory(directory) {
  const files = fs.readdirSync(directory, { withFileTypes: true });

  files.forEach((file) => {
    const filePath = path.join(directory, file.name);
    if (file.isDirectory()) {
      processDirectory(filePath); // Recurse into subdirectories
    } else if (file.name.endsWith(".sol")) {
      processFile(filePath); // Process Solidity files
    }
  });
}

// Function to process each Solidity file
function processFile(filePath) {
  let fileContent = fs.readFileSync(filePath, { encoding: "utf8" });

  // Use a regular expression to match and modify comment blocks
  let updatedContent = fileContent.replace(/\/\*\*\n([\s\S]*?)\*\//g, (match) => {
    return match
      .split("\n")
      .map((line, index, array) => {
        // Don't add '* ' to the first and last line of the comment block
        if (index === 0 || index === array.length - 1) return line;
        // Add '* ' to lines that don't start with '*'
        return line.trim().startsWith("*") ? line : line.replace(/^(\s*)/, "$1 * ");
      })
      .join("\n");
  });

  // Only update the file if changes were made to minimize disk I/O
  if (fileContent !== updatedContent) {
    fs.writeFileSync(filePath, updatedContent, { encoding: "utf8" });
    console.log(`Updated ${filePath}`);
  }
}

// Start processing from the contracts directory
const contractsDir = path.resolve(__dirname, "../contracts");
processDirectory(contractsDir);
