const fs = require('fs');
const path = require('path');

const cache = {};

// Function to recursively read through directory and process files
function processDirectory(directory, callback) {
    fs.readdirSync(directory, { withFileTypes: true }).forEach(file => {
        const fullPath = path.join(directory, file.name);
        if (/\.sol$/.test(file.name)) {
            cache[file.name] = fs.readFileSync(fullPath, 'utf8');
        }
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
    const regex = /\/\/\/ @dev see \{[\w-]+}/gs;
    return content.match(regex) || [];
}

async function extractReferencedComment(v) {
    const [ contract, func] = v.replace(/.+\{(\w+)-(\w+)}.*$/,"$1,$2").split(",");
    let res;
    if (cache[`${contract}.sol`]) {
        let c = cache[`${contract}.sol`].split("function " + func)[0].split("/**");
        c = c[c.length - 1].split("function")[0];
        res = "  /**" + c;
    }
    return res;
}

const modified = {};

async function resolveReference(value, key) {
    const solFile = key.split("/").pop();
    if (value.length > 0) {
        for (let v of value) {
            const comment = await extractReferencedComment(v);
            // console.log(key);
            cache[solFile] = cache[solFile].replace(RegExp(v.replace(/\//g, "\\/").replace(/\{/, "\\{").replace(/\}/,"\\}")), comment);
        }
    }
    modified[solFile] = cache[solFile];
}

// Main function to tie everything together
async function main() {
    const contractsPath = path.resolve(__dirname, '../../contracts');
    let globalCommentsMap = new Map();


    // Step 1: Extract NatSpec comments from all Solidity files
    processDirectory(contractsPath, (filePath) => {
        if (filePath.endsWith('.sol')) {
            const commentsMap = extractNatSpecComments(filePath);
            const relativePath = path.relative(contractsPath, filePath);
            globalCommentsMap.set(relativePath, commentsMap);
        }
    });

    globalCommentsMap.forEach(resolveReference);

    globalCommentsMap.forEach((value, key) => {
        const solFile = key.split("/").pop();
        if (modified[solFile]) {
            let f = path.join(contractsPath, key);
            console.log(f)
            // fs.writeFileSync(f, modified[solFile], 'utf8');
        }
    })
}

main().catch(console.error);
