const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");

let count = 9000;
function cl(...args) {
  console.log("\n >>>", count++, ...args, "\n");
}

const {
  increaseBlockTimestampBy,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  signRequest,
  keccak256,
} = require("./helpers");

describe("Sentinel and Inheritance", function () {
  let erc6551Registry, proxy, manager, guardian;
  let signatureValidator, vault, proxy2, inheritanceManager;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto, jerry, beneficiary1, beneficiary2;
  let chainId, ts;
  const days = 24 * 3600;

  before(async function () {
    [deployer, bob, alice, fred, mark, otto, jerry, beneficiary1, beneficiary2] = await ethers.getSigners();
    signatureValidator = await deployContract("SignatureValidator", "Cruna", "1");
    chainId = await getChainId();
  });

  beforeEach(async function () {
    erc6551Registry = await deployContract("ERC6551Registry");
    manager = await deployContract("Manager");
    guardian = await deployContract("Guardian", deployer.address);
    proxy = await deployContract("ManagersProxy", manager.address);

    vault = await deployContract(
      "CrunaFlexiVault",
      erc6551Registry.address,
      guardian.address,
      signatureValidator.address,
      proxy.address,
    );
    factory = await deployContractUpgradeable("VaultFactory", [vault.address]);

    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin");
    usdt = await deployContract("TetherUSD");

    await usdc.mint(bob.address, normalize("900"));
    await usdt.mint(alice.address, normalize("600", 6));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
    ts = (await getTimestamp()) - 100;
  });

  const buyAVault = async (bob) => {
    const price = await factory.finalPrice(usdc.address, "");
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    await factory.connect(bob).buyVaults(usdc.address, 1, "");
    const manager = await ethers.getContractAt("Manager", await vault.managerOf(nextTokenId));
    inheritanceManager = await deployContract("InheritanceManager");
    proxy2 = await deployContract("ManagersProxy", inheritanceManager.address);
    await expect(manager.connect(bob).plug("InheritanceManager", proxy2.address)).to.be.revertedWith("InvalidImplementation()");
    const scope = keccak256("InheritanceManager");
    await guardian.setTrustedImplementation(scope, proxy2.address, true);
    let pluginAddress = await manager.plugins(scope);
    expect(pluginAddress).to.equal(addr0);
    await expect(manager.connect(bob).plug("InheritanceManager", proxy2.address)).to.emit(manager, "PluginPlugged");
    pluginAddress = await manager.plugins(scope);
    expect(pluginAddress).to.not.equal(addr0);
    return nextTokenId;
  };

  it("should set up sentinel", async function () {
    await buyAVault(bob);
  });

  it("should set up sentinel", async function () {
    let tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("Manager", managerAddress);
    const inheritanceManagerAddress = await manager.plugins(keccak256("InheritanceManager"));
    const inheritanceManager = await ethers.getContractAt("InheritanceManager", inheritanceManagerAddress);
    await expect(inheritanceManager.connect(bob).setSentinel(alice.address, true, 0, 0, 0))
      .to.emit(inheritanceManager, "SentinelUpdated")
      .withArgs(bob.address, alice.address, true);
    await expect(inheritanceManager.connect(bob).setSentinel(fred.address, true, 0, 0, 0))
      .to.emit(inheritanceManager, "SentinelUpdated")
      .withArgs(bob.address, fred.address, true);
    await expect(inheritanceManager.connect(bob).setSentinel(alice.address, false, 0, 0, 0))
      .to.emit(inheritanceManager, "SentinelUpdated")
      .withArgs(bob.address, alice.address, false);
    // set Alice as a protector
    await manager.connect(bob).setProtector(alice.address, true, 0, 0, 0);
    // Set Mark as a safe recipient
    let signature = await signRequest(
      "SENTINEL",
      bob.address,
      mark.address,
      tokenId,
      true,
      ts,
      3600,
      chainId,
      alice.address,
      signatureValidator,
    );
    await expect(inheritanceManager.connect(bob).setSentinel(mark.address, true, ts, 3600, signature))
      .to.emit(inheritanceManager, "SentinelUpdated")
      .withArgs(bob.address, mark.address, true);

    // // remove Fred as a safe recipient

    signature = await signRequest(
      "SENTINEL",
      bob.address,
      fred.address,
      tokenId,
      false,
      ts,
      1000,
      chainId,
      alice.address,
      signatureValidator,
    );

    await expect(inheritanceManager.connect(bob).setSentinel(fred.address, false, ts, 3600, signature)).revertedWith(
      "WrongDataOrNotSignedByProtector",
    );

    signature = await signRequest(
      "SENTINEL",
      bob.address,
      fred.address,
      tokenId,
      false,
      ts,
      3600,
      chainId,
      alice.address,
      signatureValidator,
    );

    await expect(inheritanceManager.connect(bob).setSentinel(fred.address, false, 0, 0, 0)).revertedWith(
      "NotPermittedWhenProtectorsAreActive",
    );

    await expect(inheritanceManager.connect(bob).setSentinel(fred.address, false, ts, 3600, signature))
      .to.emit(inheritanceManager, "SentinelUpdated")
      .withArgs(bob.address, fred.address, false);
  });

  it("should set up 5 sentinels and an inheritance with a quorum 3", async function () {
    let tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("Manager", managerAddress);
    const inheritanceManagerAddress = await manager.plugins(keccak256("InheritanceManager"));
    const inheritanceManager = await ethers.getContractAt("InheritanceManager", inheritanceManagerAddress);
    await inheritanceManager
      .connect(bob)
      .setSentinels([alice.address, fred.address, otto.address, mark.address, jerry.address], 0);

    let data = await inheritanceManager.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(5);
    expect(data[0][0]).to.equal(alice.address);
    expect(data[0][1]).to.equal(fred.address);
    expect(data[0][2]).to.equal(otto.address);
    expect(data[0][3]).to.equal(mark.address);
    expect(data[0][4]).to.equal(jerry.address);
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(0);
    expect(data[1].lastProofOfLife).to.equal(0);
    expect(data[2].beneficiary).to.equal(addr0);
    expect(data[2].startedAt).to.equal(0);
    expect(data[2].approvers.length).to.equal(0);

    await expect(inheritanceManager.connect(alice).requestTransfer(beneficiary1.address)).to.be.revertedWith(
      "InheritanceNotConfigured",
    );

    await expect(inheritanceManager.connect(bob).configureInheritance(3, 90))
      .to.emit(inheritanceManager, "InheritanceConfigured")
      .withArgs(bob.address, 3, 90);

    let lastTs = await getTimestamp();

    data = await inheritanceManager.getSentinelsAndInheritanceData();
    expect(data[1].quorum).to.equal(3);
    expect(data[1].proofOfLifeDurationInDays).to.equal(90);
    expect(data[1].lastProofOfLife).to.equal(lastTs);

    await increaseBlockTimestampBy(89 * days);

    await expect(inheritanceManager.connect(bob).proofOfLife())
      .to.emit(inheritanceManager, "ProofOfLife")
      .withArgs(bob.address);

    lastTs = await getTimestamp();

    data = await inheritanceManager.getSentinelsAndInheritanceData();
    expect(data[1].lastProofOfLife).to.equal(lastTs);

    await increaseBlockTimestampBy(10 * days);

    await expect(inheritanceManager.connect(alice).requestTransfer(beneficiary1.address)).to.be.revertedWith("StillAlive");

    await increaseBlockTimestampBy(81 * days);

    await expect(inheritanceManager.requestTransfer(beneficiary1.address)).to.be.revertedWith("NotASentinel");

    await expect(inheritanceManager.connect(mark).requestTransfer(beneficiary1.address))
      .to.emit(inheritanceManager, "TransferRequested")
      .withArgs(mark.address, beneficiary1.address);
    lastTs = await getTimestamp();

    data = await inheritanceManager.getSentinelsAndInheritanceData();
    expect(data[2].beneficiary).to.equal(beneficiary1.address);
    expect(data[2].startedAt).to.equal(lastTs);
    expect(data[2].approvers.length).to.equal(1);

    await expect(inheritanceManager.connect(fred).requestTransfer(beneficiary1.address))
      .to.emit(inheritanceManager, "TransferRequestApproved")
      .withArgs(fred.address);

    data = await inheritanceManager.getSentinelsAndInheritanceData();
    expect(data[2].approvers.length).to.equal(2);

    // this should cancel the process
    await inheritanceManager.connect(bob).proofOfLife();
    lastTs = await getTimestamp();

    data = await inheritanceManager.getSentinelsAndInheritanceData();
    expect(data[2].beneficiary).to.equal(addr0);
    expect(data[2].startedAt).to.equal(0);
    expect(data[2].approvers.length).to.equal(0);

    data = await inheritanceManager.getSentinelsAndInheritanceData();
    expect(data[1].lastProofOfLife).to.equal(lastTs);

    // new attempt

    await increaseBlockTimestampBy(90 * days);

    await inheritanceManager.connect(mark).requestTransfer(beneficiary1.address);
    await inheritanceManager.connect(fred).requestTransfer(beneficiary1.address);
    await inheritanceManager.connect(otto).requestTransfer(beneficiary1.address);

    await expect(inheritanceManager.connect(beneficiary1).inherit())
      .to.emit(inheritanceManager, "InheritedBy")
      .withArgs(beneficiary1.address);

    data = await inheritanceManager.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(0);
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(0);
    expect(data[1].lastProofOfLife).to.equal(0);
    expect(data[2].beneficiary).to.equal(addr0);
    expect(data[2].startedAt).to.equal(0);
    expect(data[2].approvers.length).to.equal(0);
  });
});
