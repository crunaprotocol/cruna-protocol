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

    const managerAddress = await deployContractViaNickSFactory(deployer, "Manager", "contracts/manager");
    manager = await ethers.getContractAt("Manager", managerAddress);
    expect(manager.address).equal("0x85FD61a9FE599bd6e1e2c3E99b0dc08Ea8067F44");
    expect(await manager.version()).equal("1.0.0");

    const erc6551RegistryAddress = await deployContractViaNickSFactory(deployer, "ERC6551Registry", "erc6551");
    expect(erc6551RegistryAddress).equal("0x9B25dbEe5a7Dc1F3f9081CdD6bf3a8557Ab09196");
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", erc6551RegistryAddress);
    const account = await erc6551Registry.account(otto.address, keccak256("otto"), chainId.toString(), fred.address, 1);
    expect(account).to.be.not.equal(undefined);

    const signatureValidatorAddress = await deployContractViaNickSFactory(
      deployer,
      "SignatureValidator",
      "contracts/utils",
      ["string", "string"],
      ["Cruna", "1"],
    );
    expect(signatureValidatorAddress).equal("0xe34861e95F791fa845FcBfA41053EFC24cCb0a73");

    const guardianAddress = await deployContractViaNickSFactory(
      deployer,
      "Guardian",
      "contracts/manager",
      ["address"],
      [deployer.address],
    );
    expect(guardianAddress).equal("0xEc05d35EBE42f5aF046de9Ffcb2f12476699580c");

    const vaultAddress = await deployContractViaNickSFactory(
      deployer,
      "CrunaFlexiVault",
      "contracts",
      ["address", "address", "address", "address"],
      [erc6551RegistryAddress, guardianAddress, signatureValidatorAddress, managerAddress],
    );
    expect(vaultAddress).equal("0x8AeeCaa26e1f31fb8e169CdA8FcE0280DA1c489A");
  });

  it("should mint a vault and deploy the relative manager", async function () {
    // validate the before
  });
});
