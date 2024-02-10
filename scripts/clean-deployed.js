const fs = require("fs-extra");
const path = require("path");
const deployed = require("../export/deployed.json");

async function main() {
  let done = false;
  for (let chainId in deployed) {
    let chain = deployed[chainId];
    for (let contractName in chain) {
      if (Array.isArray(chain[contractName])) {
        chain[contractName] = chain[contractName][chain[contractName].length - 1];
        done = true;
      }
    }
  }
  if (done) {
    await fs.writeFile(path.resolve(__dirname, "../export/deployed.json"), JSON.stringify(deployed, null, 2));
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
