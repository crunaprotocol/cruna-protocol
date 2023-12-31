const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");

const {
  cl,
  amount,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  keccak256,
  deployAll,
  upgradeProxy,
  bytes4,
  deployContractViaNickSFactory,
} = require("./helpers");

describe("VaultFactory", function () {
  let crunaRegistry, proxy, managerImpl, guardian;
  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred;

  before(async function () {
    [deployer, bob, alice, fred] = await ethers.getSigners();
    // we test the deploying using Nick's factory only here because if not it would create conflicts, since any contract has already been deployed and would not change its storage
    [crunaRegistry, proxy, guardian, vault] = await deployAll(deployer);
  });

  //here we test the contract
  beforeEach(async function () {
    // process.exit();

    factory = await deployContractUpgradeable("VaultFactory", [vault.address]);

    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin");
    usdt = await deployContract("TetherUSD");

    await usdc.mint(bob.address, normalize("900"));
    await usdc.mint(fred.address, normalize("900"));
    await usdc.mint(alice.address, normalize("900"));
    await usdt.mint(alice.address, normalize("600", 6));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
    ts = (await getTimestamp()) - 100;
  });

  it("should get the precalculated address of the manager", async function () {
    let price = await factory.finalPrice(usdc.address);
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    const precalculatedAddress = await vault.managerOf(nextTokenId);
    const salt = ethers.utils.hexZeroPad(ethers.BigNumber.from("69").toHexString(), 32);

    await expect(factory.connect(bob).buyVaults(usdc.address, 1, true))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, bob.address, nextTokenId)
      .to.emit(crunaRegistry, "BoundContractCreated")
      .withArgs(
        precalculatedAddress,
        toChecksumAddress(proxy.address),
        salt,
        (await getChainId()).toString(),
        toChecksumAddress(vault.address),
        nextTokenId,
      );
  });

  async function buyVault(token, amount, buyer, alsoInit = true) {
    let price = await factory.finalPrice(token.address);
    await token.connect(buyer).approve(factory.address, price.mul(amount));
    let nextTokenId = await vault.nextTokenId();

    await expect(factory.connect(buyer).buyVaults(token.address, amount, alsoInit))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, buyer.address, nextTokenId)
      .to.emit(vault, "Transfer")
      .withArgs(addr0, buyer.address, nextTokenId.add(1))
      .to.emit(token, "Transfer")
      .withArgs(buyer.address, factory.address, price.mul(amount));
  }

  it("should not allow bob and alice to purchase vaults when paused", async function () {
    await expect(factory.pause()).to.emit(factory, "Paused");
    let price = await factory.finalPrice(usdc.address);
    await usdc.connect(fred).approve(factory.address, price);

    await expect(factory.connect(fred).buyVaults(usdc.address, 1, true)).to.be.revertedWith("Pausable: paused");

    await expect(factory.unpause()).to.emit(factory, "Unpaused");

    await buyVault(usdc, 2, bob);
    await buyVault(usdt, 2, alice);

    price = await factory.finalPrice(usdc.address);
    expect(price.toString()).to.equal("9900000000000000000");
    price = await factory.finalPrice(usdt.address);
    expect(price.toString()).to.equal("9900000");

    await expect(factory.withdrawProceeds(fred.address, usdc.address, normalize("10")))
      .to.emit(usdc, "Transfer")
      .withArgs(factory.address, fred.address, normalize("10"));
    await expect(factory.withdrawProceeds(fred.address, usdc.address, 0))
      .to.emit(usdc, "Transfer")
      .withArgs(factory.address, fred.address, amount("9.8"));
  });

  it("should allow bob and alice to purchase some vaults", async function () {
    await buyVault(usdc, 2, bob);
    await buyVault(usdt, 2, alice);

    let price = await factory.finalPrice(usdc.address);
    expect(price.toString()).to.equal("9900000000000000000");
    price = await factory.finalPrice(usdt.address);
    expect(price.toString()).to.equal("9900000");

    await expect(factory.withdrawProceeds(fred.address, usdc.address, normalize("10")))
      .to.emit(usdc, "Transfer")
      .withArgs(factory.address, fred.address, normalize("10"));
    await expect(factory.withdrawProceeds(fred.address, usdc.address, 0))
      .to.emit(usdc, "Transfer")
      .withArgs(factory.address, fred.address, amount("9.8"));
  });

  it("should allow bob to purchase some vaults without activating them", async function () {
    let nextTokenId = await vault.nextTokenId();
    await buyVault(usdc, 2, bob, false);

    expect(await vault.isActive(nextTokenId)).to.be.false;

    const precalculatedAddress = await vault.managerOf(nextTokenId);
    const salt = ethers.utils.hexZeroPad(ethers.BigNumber.from("69").toHexString(), 32);

    // console.log(keccak256("BoundContractCreated(address,address,bytes32,uint256,address,uint256)"))

    await expect(vault.connect(bob).activate(nextTokenId))
      .to.emit(crunaRegistry, "BoundContractCreated")
      .withArgs(
        precalculatedAddress,
        toChecksumAddress(proxy.address),
        salt,
        (await getChainId()).toString(),
        toChecksumAddress(vault.address),
        nextTokenId,
      );
    expect(await vault.isActive(nextTokenId)).to.be.true;
  });

  it("should allow bob and alice to purchase some vaults with a discount", async function () {
    await factory.setDiscount(100);

    await buyVault(usdc, 2, bob);
    await buyVault(usdt, 2, alice);

    let price = await factory.finalPrice(usdc.address);
    expect(price.toString()).to.equal("8900000000000000000");
    price = await factory.finalPrice(usdt.address);
    expect(price.toString()).to.equal("8900000");
  });

  it("should remove a stableCoin when active is false", async function () {
    await expect(factory.setStableCoin(usdc.address, false)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, false);

    const updatedStableCoins = await factory.getStableCoins();
    expect(updatedStableCoins).to.not.include(usdc.address);
  });

  it("should allow batch purchase of vaults", async function () {
    const stableCoin = usdc.address;
    const buyers = [bob.address, fred.address, alice.address];
    const amounts = [1, 3, 2];
    let nextTokenId = await vault.nextTokenId();

    // console.log(nextTokenId);

    let pricePerVault = await factory.finalPrice(stableCoin);

    await usdc.connect(bob).approve(factory.address, pricePerVault.mul(6));

    const bobBalanceBefore = await vault.balanceOf(bob.address);
    const fredBalanceBefore = await vault.balanceOf(fred.address);
    const aliceBalanceBefore = await vault.balanceOf(alice.address);

    await expect(factory.connect(bob).buyVaultsBatch(stableCoin, buyers, amounts, true))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, bob.address, nextTokenId)
      .to.emit(vault, "Transfer")
      .withArgs(addr0, fred.address, nextTokenId.add(1))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, fred.address, nextTokenId.add(2))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, fred.address, nextTokenId.add(3))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, alice.address, nextTokenId.add(4))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, alice.address, nextTokenId.add(5));

    expect(await vault.balanceOf(bob.address)).to.equal(bobBalanceBefore.add(1));
    expect(await vault.balanceOf(fred.address)).to.equal(fredBalanceBefore.add(3));
    expect(await vault.balanceOf(alice.address)).to.equal(aliceBalanceBefore.add(2));

    expect(await usdc.balanceOf(factory.address)).to.equal(pricePerVault.mul(6));
  });

  it("should upgrade the factory", async function () {
    const newFactory = await ethers.getContractFactory("VaultFactoryV2Mock");
    expect(await factory.version()).to.equal("1");
    await upgradeProxy(upgrades, factory.address, newFactory);
    expect(await factory.version()).to.equal("2");
  });
});
