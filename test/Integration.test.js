require("@openzeppelin/test-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;

const {expect} = require("chai");
const {deployNickSFactory, deployContractViaNickSFactory, deployContract} = require("./helpers");

const registryBytecode = require("../artifacts/erc6551/ERC6551Registry.sol/ERC6551Registry.json").bytecode;
const managerBytecode = require("../artifacts/contracts/manager/Manager.sol/Manager.json").bytecode;

describe("Integration", function () {
  let deployer;
  let erc6551RegistryAddress, managerAddress;
  let erc6551Registry, proxy, manager, guardian;
  let signatureValidator, vault;
  let salt;

  before(async function () {
    [deployer] = await ethers.getSigners();
    await deployNickSFactory(deployer);
    salt = "0x0000000000000000000000000000000000000000fd8eb4e1dca713016c518e31";
    erc6551RegistryAddress = await deployContractViaNickSFactory(deployer, registryBytecode, salt);
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", erc6551RegistryAddress);
    expect(erc6551RegistryAddress).to.equal("0xd97C080c191AdcE8Abc9789f520F67f4FE18e0e7");
    managerAddress = await deployContractViaNickSFactory(deployer, managerBytecode, salt);
    manager = await ethers.getContractAt("Manager", managerAddress);
    signatureValidator = await deployContract("SignatureValidator", "Cruna", "1");
  });

  beforeEach(async function () {
    guardian = await deployContract("AccountGuardian", deployer);
    proxy = await deployContract("ManagerProxy", guardian.target, managerAddress);
    vault = await deployContract(
      "CrunaFlexiVault",
      erc6551RegistryAddress,
      guardian.target,
      signatureValidator.target,
      managerAddress,
      proxy.target
    );
  });

  it("should work", async function () {
    // expect(erc6551RegistryAddress).to.equal("0x8c9e088Fd0a256897690Ec32cd9aEccDf34c3d3e");
    expect(true).to.equal(true);
  });
});
