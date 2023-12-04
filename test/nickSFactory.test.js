require("@openzeppelin/test-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;

const { expect } = require("chai");
const { deployNickSFactory, deployContractViaNickSFactory, getChainId, keccak256 } = require("./helpers");

describe("Nick's factory", function () {
  if (process.env.IS_COVERAGE) {
    return;
  }

  let deployer;
  let erc6551Registry, proxy, manager, guardian, signatureValidator, vault;
  let chainId;

  // We ship this because
  before(async function () {
    [deployer, bob, alice, fred, mark, otto] = await ethers.getSigners();
    chainId = await getChainId();
    await deployNickSFactory(deployer);

    const erc6551RegistryAddress = await deployContractViaNickSFactory(
      deployer,
      "ERC6551Registry",
      "erc6551",
      undefined,
      undefined,
      "0x0000000000000000000000000000000000000000fd8eb4e1dca713016c518e31",
    );
    expect(erc6551RegistryAddress).equal("0x1C723e6a4C6387df190D8E723d0f856513309779");
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", erc6551RegistryAddress);

    const managerAddress = await deployContractViaNickSFactory(deployer, "Manager", "contracts/manager");
    manager = await ethers.getContractAt("Manager", managerAddress);
    expect(manager.address).equal("0x8Fde09a3EeCF7F9f3506EC5766911F535999f607");
    expect(await manager.version()).equal(1);

    const account = await erc6551Registry.account(otto.address, keccak256("otto"), chainId.toString(), fred.address, 1);
    expect(account).to.be.not.equal(undefined);

    const signatureValidatorAddress = await deployContractViaNickSFactory(
      deployer,
      "SignatureValidator",
      "contracts/utils",
      ["string", "string"],
      ["Cruna", "1"],
    );
    expect(signatureValidatorAddress).equal("0x026E0AAC5552f022B4ce02678fE3d0365DEc7beF");

    const guardianAddress = await deployContractViaNickSFactory(
      deployer,
      "FlexiGuardian",
      "contracts/manager",
      ["address"],
      [deployer.address],
    );
    expect(guardianAddress).equal("0x29B34eb510Fa94f6Da25B73c9b8fF527c30a850B");

    const vaultAddress = await deployContractViaNickSFactory(
      deployer,
      "CrunaFlexiVault",
      "contracts",
      ["address", "address", "address", "address"],
      [erc6551RegistryAddress, guardianAddress, signatureValidatorAddress, managerAddress],
    );
    expect(vaultAddress).equal("0xda12CEC9f349d67c38f16856536D9113c4E4eA48");
  });

  it("should mint a vault and deploy the relative manager", async function () {
    // validate the before
  });
});
