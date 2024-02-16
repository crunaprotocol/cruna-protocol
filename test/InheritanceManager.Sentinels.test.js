const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");
const EthDeployUtils = require("eth-deploy-utils");
const deployUtils = new EthDeployUtils();

const {
  increaseBlockTimestampBy,
  normalize,
  deployContractUpgradeable,
  addr0,
  cl,
  signRequest,
  getChainId,
  deployContract,
  getTimestamp,
  keccak256,
  bytes4,
  selectorId,
  trustImplementation,
  combineTimestampAndValidFor,
  getCanonical,
  deployCanonical,
  pseudoAddress,
} = require("./helpers");

describe("Sentinel and Inheritance", function () {
  let crunaRegistry, proxy, managerImpl, guardian, erc6551Registry;

  let vault, inheritancePluginProxy, inheritancePluginImpl, validatorMock;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto, jerry, beneficiary1, beneficiary2, proposer, executor;
  let chainId, ts;
  const days = 24 * 3600;
  // for test only we are setting a 10 seconds delay
  let delay = 10;
  let SENTINEL = bytes4(keccak256("SENTINEL"));
  let PLUGIN_ID = bytes4(keccak256("InheritanceCrunaPlugin"));

  before(async function () {
    [deployer, proposer, executor, bob, alice, fred, mark, otto, jerry, beneficiary1, beneficiary2] = await ethers.getSigners();
    chainId = await getChainId();
    const [CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN] = await deployCanonical(deployer, proposer, executor, delay);
    crunaRegistry = await ethers.getContractAt("CrunaRegistry", CRUNA_REGISTRY);
    guardian = await ethers.getContractAt("CrunaGuardian", CRUNA_GUARDIAN);
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", ERC6551_REGISTRY);
  });

  beforeEach(async function () {
    managerImpl = await deployContract("CrunaManager");
    const deployedProxy = await deployContract("CrunaManagerProxy", managerImpl.address);
    proxy = await deployUtils.attach("CrunaManager", deployedProxy.address);
    vault = await deployContract("VaultMockSimple", deployer.address);
    await vault.init(proxy.address, 1);
    factory = await deployContractUpgradeable("VaultFactory", [vault.address, deployer.address]);
    await vault.setFactory(factory.address);

    validatorMock = await deployContract("ValidatorMock");

    usdc = await deployContract("USDCoin", deployer.address);
    usdt = await deployContract("TetherUSD", deployer.address);

    await usdc.mint(bob.address, normalize("900"));
    await usdt.mint(alice.address, normalize("600", 6));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
    ts = (await getTimestamp()) - 100;
  });

  const buyAVaultAndPlug = async (bob, withProtectors) => {
    const price = await factory.finalPrice(usdc.address);
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    await factory.connect(bob).buyVaults(usdc.address, 1);
    const manager = await ethers.getContractAt("CrunaManager", await vault.managerOf(nextTokenId));

    inheritancePluginImpl = await deployContract("InheritanceCrunaPlugin");
    inheritancePluginProxy = await deployContract("InheritanceCrunaPluginProxy", inheritancePluginImpl.address);
    inheritancePluginProxy = await deployUtils.attach("InheritanceCrunaPlugin", inheritancePluginProxy.address);

    await trustImplementation(guardian, proposer, executor, delay, PLUGIN_ID, inheritancePluginProxy.address, true, 1);
    expect((await manager.pluginsById(PLUGIN_ID, "0x00000000")).proxyAddress).to.equal(addr0);
    expect((await manager.pluginsById(PLUGIN_ID, "0x00000000")).proxyAddress).equal(addr0);
    await expect(manager.allPlugins(0)).revertedWith("");

    if (withProtectors) {
      ts = (await getTimestamp()) - 100;
      let signature = (
        await signRequest(
          await selectorId("ICrunaManager", "setProtector"),
          bob.address,
          alice.address,
          vault.address,
          nextTokenId,
          1,
          0,
          0,
          ts,
          3600,
          chainId,
          alice.address,
          manager,
        )
      )[0];

      // set Alice as Bob's protector
      await manager.connect(bob).setProtector(alice.address, true, ts, 3600, signature);

      signature = (
        await signRequest(
          await selectorId("ICrunaManager", "plug"),
          bob.address,
          inheritancePluginProxy.address,
          vault.address,
          nextTokenId,
          1,
          0,
          0,
          ts,
          3600,
          chainId,
          alice.address,
          manager,
        )
      )[0];
      await expect(
        manager
          .connect(bob)
          .plug("InheritanceCrunaPlugin", inheritancePluginProxy.address, true, false, "0x00000000", ts, 3600, signature),
      ).to.emit(manager, "PluginStatusChange");
    } else {
      await expect(
        manager.connect(bob).plug("InheritanceCrunaPlugin", inheritancePluginProxy.address, true, false, "0x00000000", 0, 0, 0),
      ).to.emit(manager, "PluginStatusChange");
    }

    expect((await manager.pluginsById(PLUGIN_ID, "0x00000000")).proxyAddress).not.equal(addr0);
    expect((await manager.allPlugins(0)).name).equal("InheritanceCrunaPlugin");
    expect((await manager.allPlugins(0)).active).to.be.true;
    const count = await manager.countPlugins();
    expect(count[0]).equal(1);
    expect(count[1]).equal(0);
    expect((await manager.listPlugins(true))[0]).equal("InheritanceCrunaPlugin");
    expect((await manager.listPlugins(false)).length).equal(0);

    expect(await manager.isPluginActive("InheritanceCrunaPlugin", "0x00000000")).to.be.true;
    expect(await manager.plugged("InheritanceCrunaPlugin", "0x00000000")).to.be.true;
    expect(await manager.plugged("InheritancePlugin2", "0x00000000")).to.be.false;

    const pluginAddress = await manager.plugin(PLUGIN_ID, "0x00000000");
    expect(pluginAddress).to.not.equal(addr0);
    return nextTokenId;
  };

  it("should verify before/beforeEach works", async function () {});

  it("should plug the plugin", async function () {
    await buyAVaultAndPlug(bob);
  });

  it("should plug the plugin when protectors are active", async function () {
    await buyAVaultAndPlug(bob, true);
  });

  it("should set up sentinels/conf w/out protectors", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.pluginAddress(nameId, "0x00000000");
    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);
    expect(await inheritancePlugin.requiresToManageTransfer()).to.be.true;
    expect(await inheritancePlugin.crunaRegistry()).to.equal(crunaRegistry.address);

    // console.log(inheritancePluginProxy.address);
    await expect(inheritancePlugin.connect(bob).setSentinel(alice.address, true, 0, 0, 0))
      .to.emit(inheritancePlugin, "SentinelUpdated")
      .withArgs(bob.address, alice.address, true);
    await expect(inheritancePlugin.connect(bob).setSentinel(fred.address, true, 0, 0, 0))
      .to.emit(inheritancePlugin, "SentinelUpdated")
      .withArgs(bob.address, fred.address, true);
    await expect(inheritancePlugin.connect(bob).setSentinel(mark.address, true, 0, 0, 0))
      .to.emit(inheritancePlugin, "SentinelUpdated")
      .withArgs(bob.address, mark.address, true);

    await expect(inheritancePlugin.connect(bob).configureInheritance(1, 90, 30, addr0, 0, 0, 0))
      .to.emit(inheritancePlugin, "InheritanceConfigured")
      .withArgs(bob.address, 1, 90, 30, addr0);
  });

  it("should set up sentinels/conf w/ or w/out protectors", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.plugin(nameId, "0x00000000");

    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);
    expect(await inheritancePlugin.requiresToManageTransfer()).to.be.true;
    await expect(inheritancePlugin.connect(bob).setSentinel(alice.address, true, 0, 0, 0))
      .to.emit(inheritancePlugin, "SentinelUpdated")
      .withArgs(bob.address, alice.address, true);
    await expect(inheritancePlugin.connect(bob).setSentinel(fred.address, true, 0, 0, 0))
      .to.emit(inheritancePlugin, "SentinelUpdated")
      .withArgs(bob.address, fred.address, true);
    await expect(inheritancePlugin.connect(bob).setSentinel(alice.address, false, 0, 0, 0))
      .to.emit(inheritancePlugin, "SentinelUpdated")
      .withArgs(bob.address, alice.address, false);

    // add the protector after the initial set up
    let signature = (
      await signRequest(
        await selectorId("ICrunaManager", "setProtector"),
        bob.address,
        alice.address,
        vault.address,
        tokenId,
        1,
        0,
        0,
        ts,
        3600,
        chainId,
        alice.address,
        manager,
      )
    )[0];

    // set Alice as first Bob's protector
    await manager.connect(bob).setProtector(alice.address, true, ts, 3600, signature);

    // Add mark
    signature = (
      await signRequest(
        await selectorId("IInheritanceCrunaPlugin", "setSentinel"),
        bob.address,
        mark.address,
        vault.address,
        tokenId,
        1,
        0,
        0,
        ts,
        3600,
        chainId,
        alice.address,
        inheritancePlugin,
      )
    )[0];

    await expect(inheritancePlugin.connect(bob).setSentinel(mark.address, true, ts, 3600, signature))
      .to.emit(inheritancePlugin, "SentinelUpdated")
      .withArgs(bob.address, mark.address, true);

    // remove Fred as a safe recipient
    await expect(inheritancePlugin.connect(bob).setSentinel(fred.address, false, 0, 0, 0)).revertedWith(
      "NotPermittedWhenProtectorsAreActive",
    );

    signature = (
      await signRequest(
        await selectorId("IInheritanceCrunaPlugin", "setSentinel"),
        bob.address,
        fred.address,
        vault.address,
        tokenId,
        0,
        0,
        0,
        ts,
        3600,
        chainId,
        alice.address,
        inheritancePlugin,
      )
    )[0];

    await expect(inheritancePlugin.connect(bob).setSentinel(fred.address, false, ts, 1, signature)).revertedWith(
      "TimestampInvalidOrExpired",
    );
    await expect(inheritancePlugin.connect(bob).setSentinel(fred.address, false, ts, 1000, signature)).revertedWith(
      "WrongDataOrNotSignedByProtector",
    );
    await expect(inheritancePlugin.connect(bob).setSentinel(fred.address, false, ts, 3600, signature))
      .to.emit(inheritancePlugin, "SentinelUpdated")
      .withArgs(bob.address, fred.address, false);
    expect(await inheritancePlugin.actorCount(SENTINEL)).equal(1);

    signature = (
      await signRequest(
        await selectorId("IInheritanceCrunaPlugin", "configureInheritance"),
        bob.address,
        addr0,
        vault.address,
        tokenId,
        3,
        90,
        30,
        ts,
        3600,
        chainId,
        alice.address,
        inheritancePlugin,
      )
    )[0];

    await expect(inheritancePlugin.connect(bob).configureInheritance(3, 90, 30, addr0, ts, 3600, signature)).revertedWith(
      "QuorumCannotBeGreaterThanSentinels",
    );

    signature = (
      await signRequest(
        await selectorId("IInheritanceCrunaPlugin", "configureInheritance"),
        bob.address,
        addr0,
        vault.address,
        tokenId,
        1,
        90,
        30,
        ts,
        3600,
        chainId,
        alice.address,
        inheritancePlugin,
      )
    )[0];

    await expect(inheritancePlugin.connect(bob).configureInheritance(1, 90, 30, addr0, ts, 3600, signature))
      .to.emit(inheritancePlugin, "InheritanceConfigured")
      .withArgs(bob.address, 1, 90, 30, addr0);
  });

  it("should set up 5 sentinels and an inheritance with a quorum 3", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const inheritancePluginAddress = await manager.plugin(PLUGIN_ID, "0x00000000");
    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);
    await inheritancePlugin
      .connect(bob)
      .setSentinels([alice.address, fred.address, otto.address, mark.address, jerry.address], 0);
    let data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(5);
    expect(data[0][0]).to.equal(alice.address);
    expect(data[0][1]).to.equal(fred.address);
    expect(data[0][2]).to.equal(otto.address);
    expect(data[0][3]).to.equal(mark.address);
    expect(data[0][4]).to.equal(jerry.address);
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(0);
    expect(data[1].lastProofOfLife).to.equal(0);
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);

    await expect(inheritancePlugin.connect(alice).requestTransfer(beneficiary1.address)).to.be.revertedWith(
      "InheritanceNotConfigured",
    );

    await expect(inheritancePlugin.connect(bob).configureInheritance(8, 90, 30, addr0, 11111111, 0, 0)).revertedWith(
      "TimestampInvalidOrExpired",
    );

    await expect(
      inheritancePlugin.connect(bob).configureInheritance(8, 90, 30, addr0, (await getTimestamp()) - 10, 36, 0x9372),
    ).revertedWith("WrongDataOrNotSignedByProtector");

    await expect(
      inheritancePlugin
        .connect(bob)
        .configureInheritance(
          8,
          90,
          30,
          addr0,
          (await getTimestamp()) - 10,
          36,
          "0x3bebc7dbc355bc64b7c6de84de84da2fe6eba6a8360654d9c76cd2a9892a570d4eeb231fcee82921f3dd7aca46cdefcaec51845dae42a1492b9df47bf43ec9821c",
        ),
    ).revertedWith("WrongDataOrNotSignedByProtector");

    await expect(inheritancePlugin.connect(bob).configureInheritance(8, 90, 30, addr0, 0, 0, 0)).revertedWith(
      "QuorumCannotBeGreaterThanSentinels",
    );
    await expect(inheritancePlugin.connect(bob).configureInheritance(3, 90, 30, addr0, 0, 0, 0))
      .to.emit(inheritancePlugin, "InheritanceConfigured")
      .withArgs(bob.address, 3, 90, 30, addr0);

    let lastTs = await getTimestamp();

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].quorum).to.equal(3);
    expect(data[1].proofOfLifeDurationInDays).to.equal(90);
    expect(data[1].lastProofOfLife).to.equal(lastTs);
    await increaseBlockTimestampBy(89 * days);

    await expect(inheritancePlugin.connect(bob).proofOfLife()).to.emit(inheritancePlugin, "ProofOfLife").withArgs(bob.address);

    lastTs = await getTimestamp();

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].lastProofOfLife).to.equal(lastTs);

    await increaseBlockTimestampBy(10 * days);

    await expect(inheritancePlugin.connect(alice).requestTransfer(beneficiary1.address)).to.be.revertedWith("StillAlive");

    await increaseBlockTimestampBy(81 * days);

    await expect(inheritancePlugin.requestTransfer(beneficiary1.address)).to.be.revertedWith("NotASentinel");

    await expect(inheritancePlugin.connect(mark).requestTransfer(beneficiary1.address))
      .to.emit(inheritancePlugin, "TransferRequested")
      .withArgs(mark.address, beneficiary1.address);
    lastTs = await getTimestamp();
    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].beneficiary).to.equal(beneficiary1.address);
    expect(data[1].requestUpdatedAt).to.equal(lastTs);
    expect(data[1].approvers.length).to.equal(1);

    await expect(inheritancePlugin.connect(fred).requestTransfer(beneficiary1.address))
      .to.emit(inheritancePlugin, "TransferRequestApproved")
      .withArgs(fred.address);

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].approvers.length).to.equal(2);

    // this should cancel the process
    await inheritancePlugin.connect(bob).proofOfLife();
    lastTs = await getTimestamp();
    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].lastProofOfLife).to.equal(lastTs);

    // new attempt

    await increaseBlockTimestampBy(90 * days);
    await inheritancePlugin.connect(mark).requestTransfer(beneficiary1.address);
    await inheritancePlugin.connect(fred).requestTransfer(beneficiary1.address);
    await inheritancePlugin.connect(otto).requestTransfer(beneficiary1.address);

    await expect(inheritancePlugin.connect(jerry).requestTransfer(beneficiary1.address)).to.be.revertedWith(
      "QuorumAlreadyReached",
    );

    await expect(inheritancePlugin.connect(beneficiary1).inherit())
      .to.emit(vault, "ManagedTransfer")
      .withArgs(PLUGIN_ID, tokenId);

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(0);
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(0);
    expect(data[1].lastProofOfLife).to.equal(0);
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);
  });

  it("should set up a beneficiary but no sentinels", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.plugin(nameId, "0x00000000");

    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);

    await expect(inheritancePlugin.connect(bob).configureInheritance(0, 90, 30, beneficiary1.address, 0, 0, 0))
      .to.emit(inheritancePlugin, "InheritanceConfigured")
      .withArgs(bob.address, 0, 90, 30, beneficiary1.address);

    let data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(90);
    expect(data[1].beneficiary).to.equal(beneficiary1.address);

    await increaseBlockTimestampBy(85 * days);
    await expect(inheritancePlugin.connect(beneficiary1).inherit()).to.be.revertedWith("StillAlive");

    await increaseBlockTimestampBy(10 * days);
    await inheritancePlugin.connect(beneficiary1).inherit();
  });

  it("should set up a beneficiary, enabling and disabling the plugin with protectors active", async function () {
    const tokenId = await buyAVaultAndPlug(bob, true);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.plugin(nameId, "0x00000000");

    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);

    const timeValidation = combineTimestampAndValidFor(ts, 3600).toString();

    let params = [
      await selectorId("IInheritanceCrunaPlugin", "setSentinel"),
      bob.address,
      mark.address,
      vault.address,
      tokenId,
      1,
      0,
      0,
      timeValidation,
    ];

    let hash = await validatorMock.hashData(...params);

    await expect(inheritancePlugin.connect(alice).preApprove(...params))
      .to.emit(inheritancePlugin, "PreApproved")
      .withArgs(hash, alice.address);

    await expect(inheritancePlugin.connect(bob).setSentinel(mark.address, true, ts, 3600, 0))
      .to.emit(inheritancePlugin, "SentinelUpdated")
      .withArgs(bob.address, mark.address, true);
    expect((await manager.listPlugins(true)).length).to.equal(1);
    expect((await manager.listPlugins(true))[0]).to.equal("InheritanceCrunaPlugin");

    await expect(manager.connect(bob).disablePlugin("InheritanceCrunaPlugin", "0x00000000", false, 0, 0, 0)).revertedWith(
      "NotPermittedWhenProtectorsAreActive",
    );

    let nameAddress = await manager.pseudoAddress("InheritanceCrunaPlugin", "0x00000000");
    expect(nameAddress).to.equal(pseudoAddress("InheritanceCrunaPlugin", "0x00000000"));
    let signature = (
      await signRequest(
        await selectorId("ICrunaManager", "disablePlugin"),
        bob.address,
        nameAddress,
        vault.address,
        tokenId,
        0,
        0,
        0,
        ts,
        3600,
        chainId,
        alice.address,
        manager,
      )
    )[0];

    await expect(manager.connect(bob).disablePlugin("InheritanceCrunaPlugin", "0x00000000", false, ts, 3600, signature))
      .to.emit(manager, "PluginStatusChange")
      .withArgs("InheritanceCrunaPlugin", inheritancePlugin.address, false);

    expect((await manager.listPlugins(true)).length).to.equal(0);

    await expect(manager.connect(bob).reEnablePlugin("InheritanceCrunaPlugin", "0x00000000", false, 0, 0, 0)).revertedWith(
      "NotPermittedWhenProtectorsAreActive",
    );

    signature = (
      await signRequest(
        await selectorId("ICrunaManager", "reEnablePlugin"),
        bob.address,
        nameAddress,
        vault.address,
        tokenId,
        0,
        0,
        0,
        ts,
        3600,
        chainId,
        alice.address,
        manager,
      )
    )[0];

    await expect(manager.connect(bob).reEnablePlugin("InheritanceCrunaPlugin", "0x00000000", false, ts, 3600, signature))
      .to.emit(manager, "PluginStatusChange")
      .withArgs("InheritanceCrunaPlugin", inheritancePlugin.address, true);

    await expect(
      manager.connect(bob).authorizePluginToTransfer("InheritanceCrunaPlugin", "0x00000000", false, 0, 0, 0, 0),
    ).revertedWith("NotPermittedWhenProtectorsAreActive");

    signature = (
      await signRequest(
        await selectorId("ICrunaManager", "authorizePluginToTransfer"),
        bob.address,
        nameAddress,
        vault.address,
        tokenId,
        0,
        30 * days,
        0,
        ts,
        3600,
        chainId,
        alice.address,
        manager,
      )
    )[0];

    await expect(
      manager
        .connect(bob)
        .authorizePluginToTransfer("InheritanceCrunaPlugin", "0x00000000", false, 30 * days, ts, 3600, signature),
    )
      .emit(manager, "PluginAuthorizationChange")
      .withArgs("InheritanceCrunaPlugin", inheritancePlugin.address, false, 30 * days);
  });

  it("should not allow to inherit if not authorized to make transfer", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.plugin(nameId, "0x00000000");

    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);

    await expect(inheritancePlugin.connect(bob).configureInheritance(0, 90, 30, beneficiary1.address, 0, 0, 0))
      .to.emit(inheritancePlugin, "InheritanceConfigured")
      .withArgs(bob.address, 0, 90, 30, beneficiary1.address);

    let data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(90);
    expect(data[1].beneficiary).to.equal(beneficiary1.address);

    await increaseBlockTimestampBy(85 * days);
    await expect(inheritancePlugin.connect(beneficiary1).inherit()).to.be.revertedWith("StillAlive");

    await expect(
      manager.connect(bob).authorizePluginToTransfer("SomeOtherPlugin", "0x00000000", true, 2 * days, 0, 0, 0),
    ).revertedWith("PluginNotFound");

    await increaseBlockTimestampBy(75 * days);

    await expect(
      manager.connect(bob).authorizePluginToTransfer("InheritanceCrunaPlugin", "0x00000000", false, 40 * days, 0, 0, 0),
    ).revertedWith("InvalidTimeLock");

    await expect(
      manager.connect(bob).authorizePluginToTransfer("InheritanceCrunaPlugin", "0x00000000", false, 0, 0, 0, 0),
    ).revertedWith("InvalidTimeLock");

    await expect(
      manager.connect(bob).authorizePluginToTransfer("InheritanceCrunaPlugin", "0x00000000", true, 10 * days, 0, 0, 0),
    ).revertedWith("InvalidTimeLock");

    await manager.connect(bob).authorizePluginToTransfer("InheritanceCrunaPlugin", "0x00000000", false, 30 * days, 0, 0, 0);
    await expect(
      manager.connect(bob).authorizePluginToTransfer("InheritanceCrunaPlugin", "0x00000000", false, 2 * days, 0, 0, 0),
    ).revertedWith("PluginAlreadyUnauthorized");

    await increaseBlockTimestampBy(10 * days);

    await expect(inheritancePlugin.connect(beneficiary1).inherit()).to.be.revertedWith("PluginNotAuthorizedToManageTransfer");

    await manager.connect(bob).authorizePluginToTransfer("InheritanceCrunaPlugin", "0x00000000", true, 0, 0, 0, 0);

    await expect(
      manager.connect(bob).authorizePluginToTransfer("InheritanceCrunaPlugin", "0x00000000", true, 0, 0, 0, 0),
    ).revertedWith("PluginAlreadyAuthorized");

    await increaseBlockTimestampBy(10 * days);
    await inheritancePlugin.connect(beneficiary1).inherit();
  });

  it("should allow to inherit only after timeLock expires", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.plugin(nameId, "0x00000000");

    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);

    await inheritancePlugin.connect(bob).configureInheritance(0, 80, 30, beneficiary1.address, 0, 0, 0);

    await increaseBlockTimestampBy(75 * days);

    await manager.connect(bob).authorizePluginToTransfer("InheritanceCrunaPlugin", "0x00000000", false, 20 * days, 0, 0, 0);

    const ts = await getTimestamp();
    expect(await manager.timeLocks(bytes4(keccak256("InheritanceCrunaPlugin")))).to.equal(ts + 20 * days);

    await increaseBlockTimestampBy(10 * days);

    await expect(inheritancePlugin.connect(beneficiary1).inherit()).to.be.revertedWith("PluginNotAuthorizedToManageTransfer");

    await increaseBlockTimestampBy(12 * days);

    await inheritancePlugin.connect(beneficiary1).inherit();
  });

  it("should set up a beneficiary and 5 sentinels and an inheritance with a quorum 3", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.plugin(nameId, "0x00000000");

    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);
    await inheritancePlugin
      .connect(bob)
      .setSentinels([alice.address, fred.address, otto.address, mark.address, jerry.address], 0);

    let data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(5);
    expect(data[0][0]).to.equal(alice.address);
    expect(data[0][1]).to.equal(fred.address);
    expect(data[0][2]).to.equal(otto.address);
    expect(data[0][3]).to.equal(mark.address);
    expect(data[0][4]).to.equal(jerry.address);
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(0);
    expect(data[1].lastProofOfLife).to.equal(0);
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);

    await expect(inheritancePlugin.connect(alice).requestTransfer(beneficiary1.address)).to.be.revertedWith(
      "InheritanceNotConfigured",
    );

    await expect(inheritancePlugin.connect(bob).configureInheritance(8, 90, 30, beneficiary1.address, 0, 0, 0)).revertedWith(
      "QuorumCannotBeGreaterThanSentinels",
    );
    await expect(inheritancePlugin.connect(bob).configureInheritance(3, 90, 30, beneficiary1.address, 0, 0, 0))
      .to.emit(inheritancePlugin, "InheritanceConfigured")
      .withArgs(bob.address, 3, 90, 30, beneficiary1.address);

    let lastTs = await getTimestamp();

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].quorum).to.equal(3);
    expect(data[1].proofOfLifeDurationInDays).to.equal(90);
    expect(data[1].lastProofOfLife).to.equal(lastTs);
    await increaseBlockTimestampBy(89 * days);

    await expect(inheritancePlugin.connect(bob).proofOfLife()).to.emit(inheritancePlugin, "ProofOfLife").withArgs(bob.address);

    lastTs = await getTimestamp();

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].lastProofOfLife).to.equal(lastTs);

    // the user disable the plugin

    await expect(manager.connect(bob).disablePlugin("InheritanceCrunaPlugin", "0x00000000", false, 0, 0, 0))
      .to.emit(manager, "PluginStatusChange")
      .withArgs("InheritanceCrunaPlugin", inheritancePlugin.address, false);

    await increaseBlockTimestampBy(100 * days);

    await expect(inheritancePlugin.connect(alice).requestTransfer(beneficiary1.address)).to.be.revertedWith(
      "WaitingForBeneficiary",
    );

    await increaseBlockTimestampBy(31 * days);

    await expect(inheritancePlugin.requestTransfer(beneficiary2.address)).to.be.revertedWith("NotASentinel");

    await expect(inheritancePlugin.connect(mark).requestTransfer(beneficiary2.address))
      .to.emit(inheritancePlugin, "TransferRequested")
      .withArgs(mark.address, beneficiary2.address);
    lastTs = await getTimestamp();
    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].beneficiary).to.equal(beneficiary2.address);
    expect(data[1].requestUpdatedAt).to.equal(lastTs);
    expect(data[1].approvers.length).to.equal(1);

    await expect(inheritancePlugin.connect(fred).requestTransfer(beneficiary2.address))
      .to.emit(inheritancePlugin, "TransferRequestApproved")
      .withArgs(fred.address);

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].approvers.length).to.equal(2);

    // this should cancel the process
    await inheritancePlugin.connect(bob).proofOfLife();
    lastTs = await getTimestamp();
    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].lastProofOfLife).to.equal(lastTs);

    // new attempt

    await increaseBlockTimestampBy(90 * days);
    await inheritancePlugin.connect(mark).requestTransfer(beneficiary2.address);
    await inheritancePlugin.connect(fred).requestTransfer(beneficiary2.address);
    await inheritancePlugin.connect(otto).requestTransfer(beneficiary2.address);

    await expect(inheritancePlugin.connect(beneficiary2).inherit()).to.be.revertedWith("PluginNotFoundOrDisabled");

    await expect(manager.connect(bob).reEnablePlugin("InheritanceCrunaPlugin", "0x00000000", false, 0, 0, 0))
      .to.emit(manager, "PluginStatusChange")
      .withArgs("InheritanceCrunaPlugin", inheritancePlugin.address, true);

    //
    await inheritancePlugin.connect(beneficiary2).inherit();

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(0);
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(0);
    expect(data[1].lastProofOfLife).to.equal(0);
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);
  });

  it("should disable and reset a plugin", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.plugin(nameId, "0x00000000");

    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);
    await inheritancePlugin
      .connect(bob)
      .setSentinels([alice.address, fred.address, otto.address, mark.address, jerry.address], 0);

    let data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(5);
    expect(data[0][0]).to.equal(alice.address);
    expect(data[0][1]).to.equal(fred.address);
    expect(data[0][2]).to.equal(otto.address);
    expect(data[0][3]).to.equal(mark.address);
    expect(data[0][4]).to.equal(jerry.address);
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(0);
    expect(data[1].lastProofOfLife).to.equal(0);
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);

    await expect(inheritancePlugin.connect(bob).configureInheritance(3, 90, 30, beneficiary1.address, 0, 0, 0))
      .to.emit(inheritancePlugin, "InheritanceConfigured")
      .withArgs(bob.address, 3, 90, 30, beneficiary1.address);

    let lastTs = await getTimestamp();

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].quorum).to.equal(3);
    expect(data[1].proofOfLifeDurationInDays).to.equal(90);
    expect(data[1].lastProofOfLife).to.equal(lastTs);
    await increaseBlockTimestampBy(89 * days);

    await expect(inheritancePlugin.connect(bob).proofOfLife()).to.emit(inheritancePlugin, "ProofOfLife").withArgs(bob.address);

    lastTs = await getTimestamp();

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].lastProofOfLife).to.equal(lastTs);

    // the user disable the plugin

    await expect(manager.connect(bob).disablePlugin("InheritanceCrunaPlugin", "0x00000000", true, 0, 0, 0))
      .to.emit(manager, "PluginStatusChange")
      .withArgs("InheritanceCrunaPlugin", inheritancePlugin.address, false);

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(0);
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(0);
    expect(data[1].lastProofOfLife).to.equal(0);
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);
  });

  it("should reset a plugin while re-enabling it", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.plugin(nameId, "0x00000000");

    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);
    await inheritancePlugin
      .connect(bob)
      .setSentinels([alice.address, fred.address, otto.address, mark.address, jerry.address], 0);

    let data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(5);
    expect(data[0][0]).to.equal(alice.address);
    expect(data[0][1]).to.equal(fred.address);
    expect(data[0][2]).to.equal(otto.address);
    expect(data[0][3]).to.equal(mark.address);
    expect(data[0][4]).to.equal(jerry.address);
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(0);
    expect(data[1].lastProofOfLife).to.equal(0);
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);

    await expect(inheritancePlugin.connect(alice).requestTransfer(beneficiary1.address)).to.be.revertedWith(
      "InheritanceNotConfigured",
    );

    await expect(inheritancePlugin.connect(bob).configureInheritance(8, 90, 30, beneficiary1.address, 0, 0, 0)).revertedWith(
      "QuorumCannotBeGreaterThanSentinels",
    );
    await expect(inheritancePlugin.connect(bob).configureInheritance(3, 90, 30, beneficiary1.address, 0, 0, 0))
      .to.emit(inheritancePlugin, "InheritanceConfigured")
      .withArgs(bob.address, 3, 90, 30, beneficiary1.address);

    let lastTs = await getTimestamp();

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].quorum).to.equal(3);
    expect(data[1].proofOfLifeDurationInDays).to.equal(90);
    expect(data[1].lastProofOfLife).to.equal(lastTs);
    await increaseBlockTimestampBy(89 * days);

    await expect(inheritancePlugin.connect(bob).proofOfLife()).to.emit(inheritancePlugin, "ProofOfLife").withArgs(bob.address);

    lastTs = await getTimestamp();

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].lastProofOfLife).to.equal(lastTs);

    // the user disable the plugin

    await expect(manager.connect(bob).disablePlugin("InheritanceCrunaPlugin", "0x00000000", false, 0, 0, 0))
      .to.emit(manager, "PluginStatusChange")
      .withArgs("InheritanceCrunaPlugin", inheritancePlugin.address, false);

    await increaseBlockTimestampBy(100 * days);

    await expect(inheritancePlugin.connect(alice).requestTransfer(beneficiary1.address)).to.be.revertedWith(
      "WaitingForBeneficiary",
    );

    await increaseBlockTimestampBy(31 * days);

    await expect(inheritancePlugin.requestTransfer(beneficiary2.address)).to.be.revertedWith("NotASentinel");

    await expect(inheritancePlugin.connect(mark).requestTransfer(beneficiary2.address))
      .to.emit(inheritancePlugin, "TransferRequested")
      .withArgs(mark.address, beneficiary2.address);
    lastTs = await getTimestamp();
    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].beneficiary).to.equal(beneficiary2.address);
    expect(data[1].requestUpdatedAt).to.equal(lastTs);
    expect(data[1].approvers.length).to.equal(1);

    await expect(inheritancePlugin.connect(fred).requestTransfer(beneficiary2.address))
      .to.emit(inheritancePlugin, "TransferRequestApproved")
      .withArgs(fred.address);

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].approvers.length).to.equal(2);

    // this should cancel the process
    await inheritancePlugin.connect(bob).proofOfLife();
    lastTs = await getTimestamp();
    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[1].lastProofOfLife).to.equal(lastTs);

    // new attempt

    await increaseBlockTimestampBy(90 * days);
    await inheritancePlugin.connect(mark).requestTransfer(beneficiary2.address);
    await inheritancePlugin.connect(fred).requestTransfer(beneficiary2.address);
    await inheritancePlugin.connect(otto).requestTransfer(beneficiary2.address);

    await expect(inheritancePlugin.connect(beneficiary2).inherit()).to.be.revertedWith("PluginNotFoundOrDisabled");

    await expect(manager.connect(bob).reEnablePlugin("InheritanceCrunaPlugin", "0x00000000", true, 0, 0, 0))
      .to.emit(manager, "PluginStatusChange")
      .withArgs("InheritanceCrunaPlugin", inheritancePlugin.address, true);

    data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(0);
    expect(data[1].quorum).to.equal(0);
    expect(data[1].proofOfLifeDurationInDays).to.equal(0);
    expect(data[1].lastProofOfLife).to.equal(0);
    expect(data[1].beneficiary).to.equal(addr0);
    expect(data[1].requestUpdatedAt).to.equal(0);
    expect(data[1].approvers.length).to.equal(0);
  });

  it("should upgrade the plugin", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.plugin(nameId, "0x00000000");

    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);
    expect(await inheritancePlugin.version()).to.equal(1e6);

    await inheritancePlugin.connect(bob).setSentinels([alice.address, fred.address], 0);

    let data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(2);

    const inheritancePluginV2Impl = await deployContract("InheritancePluginV2Mock");

    const inheritancePluginV3Impl = await deployContract("InheritancePluginV3Mock");

    await expect(inheritancePlugin.upgrade(inheritancePluginV3Impl.address)).to.be.revertedWith("NotTheTokenOwner");
    await expect(inheritancePlugin.connect(bob).upgrade(inheritancePluginV3Impl.address)).to.be.revertedWith(
      "UntrustedImplementation",
    );

    expect(bytes4(keccak256("InheritanceCrunaPlugin"))).to.equal("0xfeda9a15");
    expect(bytes4(keccak256("CrunaManager"))).to.equal("0x6fd352cb");

    const iVaultAddress = await inheritancePlugin.vault();
    const iVault = await ethers.getContractAt("VaultMockSimple", iVaultAddress);

    expect(toChecksumAddress(iVault.address)).equal(toChecksumAddress(vault.address));

    await trustImplementation(guardian, proposer, executor, delay, PLUGIN_ID, inheritancePluginV2Impl.address, true, 1);
    await trustImplementation(guardian, proposer, executor, delay, PLUGIN_ID, inheritancePluginV3Impl.address, true, 1);

    await inheritancePlugin.connect(bob).upgrade(inheritancePluginV3Impl.address);

    const newInheritancePlugin = await ethers.getContractAt("InheritancePluginV3Mock", inheritancePluginAddress);

    expect(await newInheritancePlugin.isMock()).to.be.true;
    expect(await newInheritancePlugin.version()).to.equal(1e6 + 3);
    expect(await newInheritancePlugin.SOME_OTHER_VARIABLE()).to.be.true;
    expect(await newInheritancePlugin.SOME_VARIABLE()).to.equal(3);

    data = await newInheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(2);

    await expect(inheritancePlugin.connect(bob).upgrade(inheritancePluginV2Impl.address)).to.be.revertedWith("InvalidVersion");
  });

  it("should not upgrade if the plugin requires updated manager", async function () {
    const tokenId = await buyAVaultAndPlug(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    const nameId = bytes4(keccak256("InheritanceCrunaPlugin"));
    const inheritancePluginAddress = await manager.plugin(nameId, "0x00000000");

    const inheritancePlugin = await ethers.getContractAt("InheritanceCrunaPlugin", inheritancePluginAddress);

    await inheritancePlugin.connect(bob).setSentinels([alice.address, fred.address], 0);

    let data = await inheritancePlugin.getSentinelsAndInheritanceData();
    expect(data[0].length).to.equal(2);

    const inheritancePluginV2Impl = await deployContract("InheritancePluginV2Mock");

    await trustImplementation(guardian, proposer, executor, delay, PLUGIN_ID, inheritancePluginV2Impl.address, true, 1e6 + 2e3);
    await expect(inheritancePlugin.connect(bob).upgrade(inheritancePluginV2Impl.address))
      .revertedWith("PluginRequiresUpdatedManager")
      .withArgs(1e6 + 2e3);
  });
});
