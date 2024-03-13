const fs = require('fs');
const path = require('path');

// Function to recursively read through directory and process files
function processDirectory(directory) {
    const files = fs.readdirSync(directory, { withFileTypes: true });

    files.forEach(file => {
        const filePath = path.join(directory, file.name);
        if (file.isDirectory()) {
            processDirectory(filePath); // Recurse into subdirectories
        } else if (file.name.endsWith('.sol')) {
            processFile(filePath); // Process Solidity files
        }
    });
}

// Function to process each Solidity file
function processFile(filePath) {
    let fileContent = fs.readFileSync(filePath, { encoding: 'utf8' });
    let updatedContent = fileContent.replace(/\/\*\*\n(\s*)@/g, '/**\n$1 * @');

    // Only update the file if changes were made to minimize disk I/O
    if (fileContent !== updatedContent) {
        fs.writeFileSync(filePath, updatedContent, { encoding: 'utf8' });
        console.log(`Updated ${filePath}`);
    }
}

// Start processing from the contracts directory
const contractsDir = path.resolve(__dirname, '../contracts');
processDirectory(contractsDir);
