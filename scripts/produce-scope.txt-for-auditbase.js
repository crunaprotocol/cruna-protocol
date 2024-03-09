const fs = require("fs");
const path = require("path");

// Function to recursively list all files in a directory
function listFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);

  files.forEach((file) => {
    const filePath = path.join(dir, file);
    if (fs.statSync(filePath).isDirectory()) {
      // If it's a directory, recurse into it
      if (file !== "mocks") {
        listFiles(filePath, fileList);
      }
    } else {
      if (/\.sol$/.test(file)) {
        // If it's a sol file, add it to the list
        fileList.push(filePath);
      }
    }
  });

  return fileList;
}

// Directory to search for files
const contractsDir = path.resolve(__dirname, "../contracts");

// List all files
const allFiles = listFiles(contractsDir);

// Format the file paths to be relative to the project root and Unix-like
const formattedFiles = allFiles.map((file) => file.replace(path.resolve(__dirname, "..") + "/", "").replace(/\\/g, "/"));

// Write the list of files to scope.txt
fs.writeFileSync(path.resolve(__dirname, "../scope.txt"), formattedFiles.join("\n"), "utf8");

console.log("File list has been written to scope.txt");
