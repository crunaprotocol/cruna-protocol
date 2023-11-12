require("@openzeppelin/test-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;

const {expect} = require("chai");
const {deployNickSFactory, deployContractViaNickSFactory} = require("./helpers");
const registryBytecode = require("../artifacts/erc6551/ERC6551Registry.sol/ERC6551Registry.json").bytecode;

describe("Integration", function () {
  let deployer;
  let erc6551RegistryAddress;
  let salt;

  before(async function () {
    [deployer] = await ethers.getSigners();
    await deployNickSFactory(deployer);
    salt = "0x0000000000000000000000000000000000000000fd8eb4e1dca713016c518e31";
    erc6551RegistryAddress = await deployContractViaNickSFactory(deployer, registryBytecode, salt);
    expect(erc6551RegistryAddress).to.equal("0xd97C080c191AdcE8Abc9789f520F67f4FE18e0e7");
  });

  // beforeEach(async function () {
  //
  // });

  it("should work", async function () {
    // expect(erc6551RegistryAddress).to.equal("0x8c9e088Fd0a256897690Ec32cd9aEccDf34c3d3e");
    expect(true).to.equal(true);
  });
});
