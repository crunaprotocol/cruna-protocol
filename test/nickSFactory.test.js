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
    expect(erc6551RegistryAddress).equal("0xd97C080c191AdcE8Abc9789f520F67f4FE18e0e7");
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", erc6551RegistryAddress);

    const managerAddress = await deployContractViaNickSFactory(deployer, "Manager", "contracts/manager");
    manager = await ethers.getContractAt("Manager", managerAddress);
    expect(manager.address).equal("0xD2A29EB07BBb556225D48e6C5BC52E2d0DCE1140");
    expect(await manager.version()).equal("1.0.0");

    const account = await erc6551Registry.account(otto.address, keccak256("otto"), chainId.toString(), fred.address, 1);
    expect(account).to.be.not.equal(undefined);

    const signatureValidatorAddress = await deployContractViaNickSFactory(
      deployer,
      "SignatureValidator",
      "contracts/utils",
      ["string", "string"],
      ["Cruna", "1"],
    );
    expect(signatureValidatorAddress).equal("0x5Ce315ae7749876f3E6E00ac13373Ca31f6eD02e");

    const guardianAddress = await deployContractViaNickSFactory(
      deployer,
      "Guardian",
      "contracts/manager",
      ["address"],
      [deployer.address],
    );
    expect(guardianAddress).equal("0x1b9De07B0AF7939B98233479dc618ed9f2BF3A12");

    const vaultAddress = await deployContractViaNickSFactory(
      deployer,
      "CrunaFlexiVault",
      "contracts",
      ["address", "address", "address", "address"],
      [erc6551RegistryAddress, guardianAddress, signatureValidatorAddress, managerAddress],
    );
    expect(vaultAddress).equal("0xF21095e85283Eb2a29f967461081f8E9eE547734");
  });

  it("should mint a vault and deploy the relative manager", async function () {
    // validate the before
  });
});
