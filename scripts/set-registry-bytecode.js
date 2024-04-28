require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const fs = require("fs-extra");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  let deployer;
  const chainId = await deployUtils.currentChainId();
  [deployer] = await ethers.getSigners();

  const bytecodesPath = path.resolve(
    __dirname,
    chainId === 1337 ? "../test/helpers/bytecodes.json" : "../contracts/canonicalBytecodes.json",
  );

  let bytecodes;
  if (fs.existsSync(bytecodesPath)) {
    bytecodes = JSON.parse(fs.readFileSync(bytecodesPath, "utf8"));
  } else {
    bytecodes = {
      ERC7656Registry: {},
    };
  }

  const canonicalPath = path.resolve(
    __dirname,
    `../libs-canonical/${chainId === 1337 ? "not-" : ""}localhost/GuardianInstance.sol`,
  );

  // This is supposed to happen only during development when there are breaking changes.
  // It should not happen after the first guardian as been deployed, except if very serious
  // issues are found and a new guardian is needed. In that unfortunate case, all managers
  // and services will have to be upgraded by tokens' owners.
  let salt = bytecodes.ERC7656Registry.salt || ethers.constants.HashZero;
  bytecodes.ERC7656Registry.salt = salt;

  bytecodes.ERC7656Registry.bytecode = await deployUtils.getBytecodeToBeDeployedViaNickSFactory(deployer, "ERC7656Registry");

  let canonical = fs.readFileSync(canonicalPath, "utf8");
  let newAddress = await deployUtils.getAddressOfContractDeployedWithBytecodeViaNickSFactory(
    deployer,
    bytecodes.ERC7656Registry.bytecode,
    salt,
  );
  bytecodes.ERC7656Registry.address = newAddress;

  const canonical2 = canonical.replace(/IERC7656Registry\([^)]+\)/, `IERC7656Registry(${newAddress})`);
  if (canonical2 === canonical) {
    console.log("No change in the bytecode");
  }

  fs.writeFileSync(bytecodesPath, JSON.stringify(bytecodes, null, 2));
  fs.writeFileSync(canonicalPath, canonical2);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
