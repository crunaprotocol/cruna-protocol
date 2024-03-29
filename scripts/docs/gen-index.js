const fs = require("fs");
const path = require("path");

// Function to recursively scan a directory for Markdown files and organize them by directory
function findMarkdownFiles(directory, fileList = {}, parentPath = "") {
  const files = fs.readdirSync(directory, { withFileTypes: true });

  files.forEach((file) => {
    const filePath = path.join(directory, file.name);
    const relativeFilePath = path.join(parentPath, file.name);
    if (file.isDirectory()) {
      // Recurse into subdirectories
      findMarkdownFiles(filePath, fileList, relativeFilePath);
    } else if (file.name.endsWith(".md") && file.name !== "README.md") {
      const dir = parentPath || ".";
      if (!fileList[dir]) {
        fileList[dir] = [];
      }
      fileList[dir].push(relativeFilePath);
    }
  });

  return fileList;
}

function capitalizeFirstLetter(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

// Function to generate index.md content from the organized Markdown file paths
function generateIndexContent(markdownFiles, baseDir) {
  let indexContent = "\n\n";
  for (const [dir, files] of Object.entries(markdownFiles)) {
    if (dir !== ".") {
      indexContent += `- ${capitalizeFirstLetter(dir)}\n`;
    }
    files.forEach((filePath) => {
      const fileName = path.basename(filePath, ".md");
      const relativePath = path.relative(baseDir, filePath).replace(/^\./, "");
      indexContent += `  - [${fileName}](${relativePath})\n`;
    });
  }
  return indexContent;
}

// Base directory where the Markdown files are located
const baseDir = path.resolve(__dirname, "../../docs");

// Find all Markdown files organized by directory
const markdownFiles = findMarkdownFiles(baseDir);

const intro = fs.readFileSync(path.join(__dirname, "intro.md"), "utf8");

// Generate index content
let indexContent = intro + generateIndexContent(markdownFiles, baseDir);

indexContent += `

The documentation is automatically generated using [solidity-docgen](https://github.com/OpenZeppelin/solidity-docgen)

(c) 2024+ Cruna
`;

// Write the index file
const indexPath = path.join(baseDir, "README.md");
fs.writeFileSync(indexPath, indexContent, "utf8");

console.log(`docs/README.md has been created with entries organized by directory.`);
