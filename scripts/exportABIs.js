const fs = require("fs-extra");
const path = require("path");

async function main() {
  const ABIs = {
    when: new Date().toISOString(),
    contracts: {},
  };

  function abi(name, folder, rename) {
    let source = path.resolve(__dirname, `../artifacts/${folder ? folder + "/" : ""}${name}.sol/${name}.json`);
    let json = require(source);
    ABIs.contracts[rename || name] = json.abi;
  }
  abi("ERC6551Registry", "erc6551");
  abi("Manager", "contracts/managers");
  abi("CrunaFlexiVault", "contracts");
  abi("SignatureValidator", "contracts/utils");
  abi("Guardian", "contracts/managers");
  abi("VaultFactory", "contracts/factory");

  // for dev only
  abi("USDCoin", "contracts/mocks/fake-tokens");
  abi("TetherUSD", "contracts/mocks/fake-tokens");

  await fs.writeFile(path.resolve(__dirname, "../export/ABIs.json"), JSON.stringify(ABIs, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
