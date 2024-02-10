
const deployed = require("../export/deployed.json");
const path = require("path");
const fs = require("fs-extra");

function getLatestOnly(deployed) {
  let latest = {};
  for (let chainId in deployed) {
    latest[chainId] = {};
    for (let contract in deployed[chainId]) {
      if (typeof deployed[chainId][contract] === "string") {
        deployed[chainId][contract] = [deployed[chainId][contract]];
      }
      latest[chainId][contract] = deployed[chainId][contract][deployed[chainId][contract].length - 1];
    }
  }
  return latest;
}
async function main() {
  let filtered = getLatestOnly(deployed);
  await fs.writeFile(path.resolve(__dirname, "../export/deployed.json"), JSON.stringify(filtered, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
