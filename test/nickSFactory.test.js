require("@openzeppelin/test-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;

const {expect} = require("chai");
const {deployNickSFactory, deployContractViaNickSFactory, nickSFactoryAddress} = require("./helpers");

const registryBytecode = require("../artifacts/erc6551/ERC6551Registry.sol/ERC6551Registry.json").bytecode;
const managerBytecode = require("../artifacts/contracts/manager/Manager.sol/Manager.json").bytecode;

describe.skip("Nick's factory", function () {
  let deployer;
  let erc6551RegistryAddress, managerAddress;
  let salt;

  before(async function () {
    [deployer] = await ethers.getSigners();
    await deployNickSFactory(deployer);
    expect(await ethers.provider.getCode(nickSFactoryAddress)).not.equal("0x");
    salt = "0x0000000000000000000000000000000000000000fd8eb4e1dca713016c518e31";
    erc6551RegistryAddress = await deployContractViaNickSFactory(deployer, registryBytecode, salt);
    expect(await ethers.provider.getCode(erc6551RegistryAddress)).not.equal("0x");
    managerAddress = await deployContractViaNickSFactory(deployer, managerBytecode, salt);
    expect(await ethers.provider.getCode(managerAddress)).not.equal("0x");
  });


  it("should mint a valut and deploy the relative manager", async function () {
    // await expect(vault.
  });
});
