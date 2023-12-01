const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");

let count = 9000;
function cl(...args) {
  console.log(count++, ...args);
}

const {
  amount,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  signRequest,
  keccak256,
} = require("./helpers");

describe("Manager : Protectors", function () {
  let erc6551Registry, proxy, managerImpl, guardian;
  let signatureValidator, vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto;
  let chainId, ts;

  before(async function () {
    [deployer, bob, alice, fred, mark, otto] = await ethers.getSigners();
    signatureValidator = await deployContract("SignatureValidator", "Cruna", "1");
    chainId = await getChainId();
  });

  beforeEach(async function () {
    erc6551Registry = await deployContract("ERC6551Registry");
    managerImpl = await deployContract("Manager");
    guardian = await deployContract("Guardian", deployer.address);
    proxy = await deployContract("ManagerProxy", managerImpl.address);

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
    return nextTokenId;
  };

  it("should support the IProtected interface", async function () {
    const vaultMock = await deployContract(
      "VaultMock",
      erc6551Registry.address,
      guardian.address,
      signatureValidator.address,
      proxy.address,
    );
    const interfaceId = await vaultMock.getIProtectedInterfaceId();
    expect(interfaceId).to.equal("0x0009b66d");
    expect(await vault.supportsInterface(interfaceId)).to.be.true;
  });

  it("should verify ManagerBase parameters", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("Manager", managerAddress);

    expect(await manager.version()).to.equal("1.0.0");
    expect(await manager.tokenId()).to.equal(tokenId);
    expect(await manager.tokenAddress()).to.equal(vault.address);
    expect(await manager.owner()).to.equal(bob.address);
    expect(await manager.token()).deep.equal([ethers.BigNumber.from(chainId.toString()), vault.address, tokenId]);
  });

  it("should verify vault base parameters", async function () {
    expect(await vault.defaultLocked()).to.be.false;
    const tokenId = await buyAVault(bob);
    expect(await vault.tokenURI(tokenId)).to.equal("https://meta.cruna.cc/flexy-vault/v1/31337000001");
    expect(await vault.contractURI()).to.equal("https://meta.cruna.cc/flexy-vault/v1/info");
    expect(await vault.locked(tokenId)).to.be.false;
    expect(await vault.isTransferable(tokenId, bob.address, addr0)).to.be.false;
    expect(await vault.isTransferable(tokenId, bob.address, bob.address)).to.be.false;
  });

  it("should add the first protector and remove it", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("Manager", managerAddress);

    expect(await vault.supportsInterface("0x80ac58cd")).to.equal(true);

    // set Alice as first Bob's protector
    await expect(manager.connect(bob).setProtector(alice.address, true, 0, 0, 0))
      .to.emit(manager, "ProtectorUpdated")
      .withArgs(bob.address, alice.address, true)
      .to.emit(vault, "Locked")
      .withArgs(tokenId, true);

    await expect(manager.connect(bob).setProtector(alice.address, false, 0, 0, 0)).to.be.revertedWith(
      "NotPermittedWhenProtectorsAreActive",
    );

    let signature = await signRequest(
      "PROTECTOR",
      bob.address,
      alice.address,
      tokenId,
      false,
      ts,
      3600,
      chainId,
      alice.address,
      signatureValidator,
    );

    await expect(manager.connect(bob).setProtector(alice.address, true, ts, 3600, signature)).to.be.revertedWith(
      "WrongDataOrNotSignedByProtector",
    );

    await expect(manager.connect(bob).setProtector(alice.address, false, ts, 3600, signature))
      .to.emit(manager, "ProtectorUpdated")
      .withArgs(bob.address, alice.address, false)
      .to.emit(vault, "Locked")
      .withArgs(tokenId, false);
  });

  it("should throw is wrong data for first protector", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("Manager", managerAddress);
    // set Alice as first Bob's protector
    await expect(manager.connect(bob).setProtector(addr0, true, 0, 0, 0)).revertedWith("ZeroAddress");
    await expect(manager.connect(bob).setProtector(bob.address, true, 0, 0, 0)).revertedWith("CannotBeYourself");
  });

  it("should add many protectors", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("Manager", managerAddress);

    expect(await manager.hasProtectors()).to.equal(false);

    // set Alice as first Bob's protector
    await manager.connect(bob).setProtector(alice.address, true, 0, 0, 0);
    // Set Fred as Bob's protector
    // To do so Bob needs Alice's signature

    let allProtectors = await manager.getProtectors();
    expect(allProtectors[0]).equal(alice.address);

    let signature = await signRequest(
      "PROTECTOR",
      bob.address,
      fred.address,
      tokenId,
      true,
      ts,
      3600,
      chainId,
      alice.address,
      signatureValidator,
    );
    await expect(manager.connect(bob).setProtector(fred.address, true, ts, 3600, signature))
      .to.emit(manager, "ProtectorUpdated")
      .withArgs(bob.address, fred.address, true);

    allProtectors = await manager.getProtectors();
    expect(allProtectors[1]).equal(fred.address);

    // test listProtectors is of type array and that it has two protector addresses
    // and that the second address is fred's.
    let totalProtectors = await manager.listProtectors();
    expect(totalProtectors).to.be.an("array");
    expect(await totalProtectors.length).to.equal(2);
    expect(totalProtectors[1]).equal(fred.address);

    expect(await manager.hasProtectors()).to.equal(true);

    // let Fred remove Alice as protector
    signature = await signRequest(
      "PROTECTOR",
      bob.address,
      alice.address,
      tokenId,
      false,
      ts,
      3600,
      chainId,
      fred.address,
      signatureValidator,
    );
    await expect(manager.connect(bob).setProtector(alice.address, false, ts, 3600, signature))
      .to.emit(manager, "ProtectorUpdated")
      .withArgs(bob.address, alice.address, false);

    expect(await manager.findProtectorIndex(fred.address)).to.equal(0);
  });

  it("should add a protector and transfer a vault", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("Manager", managerAddress);
    // set Alice as Bob's protector
    await manager.connect(bob).setProtector(alice.address, true, 0, 0, 0);
    await expect(
      vault.connect(bob)["safeTransferFrom(address,address,uint256)"](bob.address, fred.address, tokenId),
    ).to.be.revertedWith("NotTransferable");
    let signature = await signRequest(
      "PROTECTED_TRANSFER",
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
    await expect(vault.connect(bob).protectedTransfer(tokenId, fred.address, ts, 3600, signature))
      .to.emit(vault, "Transfer")
      .withArgs(bob.address, fred.address, tokenId);
  });

  it("should allow bob to upgrade the manager", async function () {
    const tokenId = await buyAVault(bob);
    const managerV2Impl = await deployContract("ManagerV2Mock");
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("Manager", managerAddress);
    expect(await manager.version()).to.equal("1.0.0");

    await manager.connect(bob).setProtector(alice.address, true, 0, 0, 0);
    expect(await manager.hasProtectors()).to.equal(true);

    await expect(manager.upgrade(managerV2Impl.address)).to.be.revertedWith("NotTheTokenOwner");

    await expect(manager.connect(bob).upgrade(managerV2Impl.address)).to.be.revertedWith("InvalidImplementation");

    await guardian.setTrustedImplementation(keccak256("Manager"), managerV2Impl.address, true);

    expect(await manager.getImplementation()).to.equal(addr0);

    await manager.connect(bob).upgrade(managerV2Impl.address);
    expect(await manager.getImplementation()).to.equal(managerV2Impl.address);

    expect(await manager.version()).to.equal("2.0.0");
    expect(await manager.hasProtectors()).to.equal(true);

    const managerV2 = await ethers.getContractAt("ManagerV2Mock", managerAddress);
    expect(await managerV2.isMock()).to.be.true;
  });
});
