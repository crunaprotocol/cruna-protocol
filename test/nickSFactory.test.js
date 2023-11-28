require("@openzeppelin/test-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;

const { expect } = require("chai");
const { deployNickSFactory, deployContractViaNickSFactory, getChainId } = require("./helpers");

describe.only("Nick's factory", function () {
  let deployer;
  let erc6551Registry, proxy, manager, guardian, signatureValidator, vault;
  let chainId;

  before(async function () {
    [deployer, bob, alice, fred, mark, otto] = await ethers.getSigners();
    chainId = await getChainId();
    await deployNickSFactory(deployer);
    erc6551Registry = await deployContractViaNickSFactory(deployer, "ERC6551Registry", "erc6551");
    expect(erc6551Registry.address).equal("0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");

    return;
    manager = await deployContractViaNickSFactory(deployer, "Manager", "contracts/manager");
    expect(manager.address).equal("0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9");
    guardian = await deployContractViaNickSFactory(deployer, "Guardian", "contracts/manager", deployer.address);
    expect(guardian.address).equal("0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9");
    proxy = await deployContractViaNickSFactory(deployer, "ManagerProxy", "contracts/manager", manager.address);
    expect(proxy.address).equal("0x5FC8d32690cc91D4c39d9d3abcBD16989F875707");
    vault = await deployContractViaNickSFactory(
      deployer,
      "CrunaFlexiVault",
      "contracts",
      erc6551Registry.address,
      guardian.address,
      signatureValidator.address,
      proxy.address,
    );
    expect(vault.address).equal("0x0165878A594ca255338adfa4d48449f69242Eb8F");
    signatureValidator = await deployContractViaNickSFactory(deployer, "SignatureValidator", "contracts/utils", "Cruna", "1");
  });

  it("should mint a vault and deploy the relative manager", async function () {
    // validate the before
  });
});
