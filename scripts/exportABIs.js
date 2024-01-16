const fs = require("fs-extra");
const path = require("path");

async function main() {
  const ABIs = {

  };

  function abi(name, folder, rename) {
    let source = path.resolve(__dirname, `../artifacts/${folder ? folder + "/" : ""}${name}.sol/${name}.json`);
    let json = require(source);
    ABIs[rename || name] = json.abi;
  }
  abi("CrunaRegistry", "contracts/utils");
  abi("Manager", "contracts/manager");
  abi("FlexiProxy", "contracts/utils");
  abi("InheritancePlugin", "contracts/plugins/inheritance");
  abi("InheritancePluginProxy", "contracts/plugins/inheritance");
  abi("VaultMock", "contracts/mocks");
  abi("SignatureValidator", "contracts/utils");
  abi("Guardian", "contracts/utils");
  abi("VaultFactoryMock", "contracts/mocks/factory");

  // for dev only
  // abi("USDCoin", "contracts/mocks/fake-tokens");
  // abi("TetherUSD", "contracts/mocks/fake-tokens");
  //
  // abi("ERC20", "@openzeppelin/contracts/token/ERC20");
  // abi("ERC721", "@openzeppelin/contracts/token/ERC721");
  // abi("ERC1155", "@openzeppelin/contracts/token/ERC1155");
  // abi("ERC721Enumerable", "@openzeppelin/contracts/token/ERC721/extensions");

  await fs.writeFile(path.resolve(__dirname, "../export/ABIs.json"), JSON.stringify(ABIs, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
