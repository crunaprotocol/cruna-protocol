const fs = require("fs-extra");
const path = require("path");

async function main() {
  const ABIs = {};

  function abi(name, folder, rename) {
    let source = path.resolve(__dirname, `../artifacts/${folder ? folder + "/" : ""}${name}.sol/${name}.json`);
    let json = require(source);
    ABIs[rename || name] = json.abi;
  }
  abi("CrunaManager", "contracts/manager");
  abi("ERC7656Registry", "erc7656");
  abi("InheritanceCrunaPlugin", "contracts/services/inheritance");
  abi("TimeControlledNFT", "contracts/mocks/token");
  abi("CrunaGuardian", "contracts/guardian");
  abi("VaultFactory", "contracts/mocks/factory");
  abi("ERC6551Registry", "erc6551");

  await fs.writeFile(path.resolve(__dirname, "../export/Cruna.json"), JSON.stringify(ABIs, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
