const fs = require('fs');
const path = require('path');

// Function to recursively read through directory and process files
function processDirectory(directory, callback) {
    fs.readdirSync(directory, { withFileTypes: true }).forEach(file => {
        const fullPath = path.join(directory, file.name);
        if (file.isDirectory()) {
            processDirectory(fullPath, callback); // Recurse into directories
        } else {
            callback(fullPath);
        }
    });
}

// Function to extract NatSpec comments from Solidity files
function extractNatSpecComments(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    const regex = /\/\*\*(\s+\*\s+@.*?)+\s+\*\//gs;
    const comments = content.match(regex) || [];

    let commentsMap = new Map();
    comments.forEach(comment => {
        const identifier = comment.match(/@title\s+([A-Za-z0-9_]+)/)?.[1] || comment.match(/@dev\s+([^\n]+)/)?.[1];
        if (identifier) {
            commentsMap.set(identifier.trim(), comment);
        }
    });
    return commentsMap;
}

// Function to resolve references in Markdown files
function updateMarkdown(filePath, commentsMap) {
    let mdContent = fs.readFileSync(filePath, 'utf8');
    const referenceRegex = /\_see \{([A-Za-z0-9_-]+)\}\_/g;

    mdContent = mdContent.replace(referenceRegex, (match, identifier) => {
        const comment = commentsMap.get(identifier);
        return comment ? comment.replace(/\/\*\*|\*\//g, '').trim() : match;
    });

    fs.writeFileSync(filePath, mdContent, 'utf8');
}

// Main function to tie everything together
async function main() {
    const contractsPath = path.resolve(__dirname, '../contracts');
    const docsPath = path.resolve(__dirname, '../docs');
    let globalCommentsMap = new Map();

    // Step 1: Extract NatSpec comments from all Solidity files
    processDirectory(contractsPath, (filePath) => {
        if (filePath.endsWith('.sol')) {
            const commentsMap = extractNatSpecComments(filePath);
            const relativePath = path.relative(contractsPath, filePath);
            globalCommentsMap.set(relativePath, commentsMap);
        }
    });

    console.log(globalCommentsMap)

    // Step 2: Update corresponding Markdown files
    processDirectory(docsPath, (filePath) => {
        if (filePath.endsWith('.md')) {
            const relativePath = path.relative(docsPath, filePath).replace(/\.md$/, '.sol');
            const commentsMap = globalCommentsMap.get(relativePath);
            if (commentsMap) {
                updateMarkdown(filePath, commentsMap);
            }
        }
    });
}

main().catch(console.error);
