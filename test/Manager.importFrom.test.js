const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");
const EthDeployUtils = require("eth-deploy-utils");
const deployUtils = new EthDeployUtils();

const {
  amount,
  cl,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  signRequest,
  selectorId,
  bytes4,
  keccak256,

  deployCanonical,
  setFakeCanonicalIfCoverage,
} = require("./helpers");

describe("CrunaManager : importProtectorsAndSafeRecipientsFrom ", function () {
  let crunaRegistry, proxy, managerImpl, guardian, erc6551Registry;

  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto, proposer, executor;
  let chainId, ts;
  const delay = 10;
  let CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN;

  async function setProtector(manager, owner, actor, tokenId, protector, active) {
    let signature = (
      await signRequest(
        await selectorId("ICrunaManager", "setProtector"),
        owner.address,
        actor.address,
        vault.address,
        tokenId,
        active ? 1 : 0,
        0,
        0,
        ts,
        3600,
        chainId,
        protector.address,
        manager,
      )
    )[0];

    await expect(manager.connect(owner).setProtector(actor.address, active, ts, 3600, signature))
      .to.emit(manager, "ProtectorChange")
      .withArgs(actor.address, active);
  }

  before(async function () {
    [deployer, proposer, executor, bob, alice, fred, mark, otto] = await ethers.getSigners();
    chainId = await getChainId();
    [CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN] = await deployCanonical(deployer, proposer, executor, delay);
    crunaRegistry = await ethers.getContractAt("CrunaRegistry", CRUNA_REGISTRY);
    guardian = await ethers.getContractAt("CrunaGuardian", CRUNA_GUARDIAN);
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", ERC6551_REGISTRY);
  });

  beforeEach(async function () {
    managerImpl = await deployContract("CrunaManager");
    proxy = await deployContract("CrunaManagerProxy", managerImpl.address);
    proxy = await deployUtils.attach("CrunaManager", proxy.address);

    vault = await deployContract("OwnableNFT", deployer.address);

    await vault.init(proxy.address, 1, true);
    factory = await deployContractUpgradeable("VaultFactory", [vault.address, deployer.address]);

    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin", deployer.address);
    usdt = await deployContract("TetherUSD", deployer.address);

    await usdc.mint(bob.address, normalize("900"));
    await usdc.mint(alice.address, normalize("900"));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
    ts = (await getTimestamp()) - 100;
  });

  const buyAVault = async (bob) => {
    const price = await factory.finalPrice(usdc.address);
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    await factory.connect(bob).buyVaults(usdc.address, 1);

    const managerAddress = await vault.managerOf(nextTokenId);
    await ethers.getContractAt("CrunaManager", managerAddress);

    return nextTokenId;
  };

  it("should import from another tokenId", async function () {
    // cl(true)
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    const tokenId1 = await buyAVault(bob);
    const managerAddress1 = await vault.managerOf(tokenId1);
    const manager1 = await ethers.getContractAt("CrunaManager", managerAddress1);

    await expect(manager1.connect(bob).importProtectorsAndSafeRecipientsFrom(tokenId)).revertedWith("NothingToImport");

    // set Alice and Fred as a safe recipient
    await expect(manager.connect(bob).setSafeRecipient(alice.address, true, 0, 0, 0))
      .to.emit(manager, "SafeRecipientChange")
      .withArgs(alice.address, true);
    await expect(manager.connect(bob).setSafeRecipient(fred.address, true, 0, 0, 0))
      .to.emit(manager, "SafeRecipientChange")
      .withArgs(fred.address, true);

    expect(await manager.getSafeRecipients()).deep.equal([alice.address, fred.address]);

    await setProtector(manager, bob, mark, tokenId, mark, true);
    await setProtector(manager, bob, otto, tokenId, mark, true);

    // new token

    const tokenId2 = await buyAVault(alice);
    const managerAddress2 = await vault.managerOf(tokenId2);
    const manager2 = await ethers.getContractAt("CrunaManager", managerAddress2);

    await expect(manager2.connect(alice).importProtectorsAndSafeRecipientsFrom(tokenId)).revertedWith("NotTheSameOwner");

    const tokenId3 = await buyAVault(bob);
    const managerAddress3 = await vault.managerOf(tokenId3);
    const manager3 = await ethers.getContractAt("CrunaManager", managerAddress3);

    await expect(manager3.connect(bob).importProtectorsAndSafeRecipientsFrom(tokenId3)).revertedWith(
      "CannotimportProtectorsAndSafeRecipientsFromYourself",
    );

    await expect(manager3.connect(bob).importProtectorsAndSafeRecipientsFrom(tokenId))
      .emit(manager3, "ProtectorChange")
      .withArgs(mark.address, true)
      .emit(manager3, "ProtectorChange")
      .withArgs(otto.address, true)
      .emit(manager3, "SafeRecipientChange")
      .withArgs(alice.address, true)
      .emit(manager3, "SafeRecipientChange")
      .withArgs(fred.address, true)
      .emit(vault, "Locked")
      .withArgs(tokenId3, true);
  });

  it("should revert if a protectors already set", async function () {
    // cl(true)
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    const tokenId1 = await buyAVault(bob);
    const managerAddress1 = await vault.managerOf(tokenId1);
    const manager1 = await ethers.getContractAt("CrunaManager", managerAddress1);

    await expect(manager1.connect(bob).importProtectorsAndSafeRecipientsFrom(tokenId)).revertedWith("NothingToImport");

    // set Alice and Fred as a safe recipient
    await expect(manager.connect(bob).setSafeRecipient(alice.address, true, 0, 0, 0))
      .to.emit(manager, "SafeRecipientChange")
      .withArgs(alice.address, true);
    await expect(manager.connect(bob).setSafeRecipient(fred.address, true, 0, 0, 0))
      .to.emit(manager, "SafeRecipientChange")
      .withArgs(fred.address, true);

    expect(await manager.getSafeRecipients()).deep.equal([alice.address, fred.address]);

    await setProtector(manager, bob, mark, tokenId, mark, true);
    await setProtector(manager, bob, otto, tokenId, mark, true);

    // new token

    const tokenId2 = await buyAVault(bob);
    const managerAddress2 = await vault.managerOf(tokenId2);
    const manager2 = await ethers.getContractAt("CrunaManager", managerAddress2);

    await setProtector(manager2, bob, mark, tokenId2, mark, true);

    await expect(manager2.connect(alice).importProtectorsAndSafeRecipientsFrom(tokenId)).revertedWith("NotTheTokenOwner");
    await expect(manager2.connect(bob).importProtectorsAndSafeRecipientsFrom(tokenId)).revertedWith("ProtectorsAlreadySet");
  });
});
