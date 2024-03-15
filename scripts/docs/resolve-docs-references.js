const fs = require('fs');
const path = require('path');

const cache = {};
const globalCommentsMap = {}

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
    const regex = /\/\/\/ @dev see \{[\w-_]+}/gs;
    return content.match(regex) || [];
}

async function extractReferencedComment(v) {
    const [ contract, func] = v.replace(/.+\{(\w+)-((_|)\w+)}.*$/,"$1,$2").split(",");
    let res;
    if (cache[`${contract}.sol`]) {
        let c = cache[`${contract}.sol`].split("function " + func)[0].split("/**");
        // c = c[c.length - 1].split("function")[0];
        res = "  /**" + c[c.length - 1];
    }
    return res;
}

function escapeRegExp(string) {
    // This function escapes special characters for use in a regular expression
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
}

async function resolveReference(value, key) {
    const solFile = key.split("/").pop();
    if (value.length > 0) {
        for (let v of value) {
            const comment = await extractReferencedComment(v);
            if (comment) {
                let re = new RegExp(escapeRegExp(v));
                // if (solFile == "CrunaManager.sol") {
                //     console.log(comment);
                //     console.log(re.test(cache[solFile]));
                //     console.log(cache[solFile].replace(re, comment));
                // }
                cache[solFile] = cache[solFile].replace(re, comment)
            }
        }
    }
}

// Main function to tie everything together
async function main() {
    const contractsPath = path.resolve(__dirname, '../../contracts');



    // Step 1: Extract NatSpec comments from all Solidity files
    processDirectory(contractsPath, (filePath) => {
        if (filePath.endsWith('.sol')) {
            const commentsMap = extractNatSpecComments(filePath);
            const relativePath = path.relative(contractsPath, filePath);
            globalCommentsMap[relativePath] = commentsMap;
        }
    });

    const startCache = JSON.parse(JSON.stringify(cache));
    // console.log(startCache["CrunaGuardian.sol"]);

    for (let key in globalCommentsMap) {
        await resolveReference(globalCommentsMap[key], key);
    }
    // console.log(cache["CrunaManager.sol"]);
    // console.log(cache);

    for (let key in globalCommentsMap) {
        const solFile = key.split("/").pop();
        if (startCache[solFile] !== cache[solFile]) {
            // console.log(solFile);
            let f = path.join(contractsPath, key);
            // console.log(f)
            fs.writeFileSync(f, cache[solFile], 'utf8');
        }
    }
}

main().catch(console.error);
