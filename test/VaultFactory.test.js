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
  deployAll,
  upgradeProxy,
  executeAndReturnGasCost,
} = require("./helpers");

describe("VaultFactoryMock", function () {
  let registry, proxy, guardian;
  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mike;

  before(async function () {
    [deployer, bob, alice, fred, mike] = await ethers.getSigners();
    // we test the deploying using Nick's factory only here because if not it would create conflicts, since any contract has already been deployed and would not change its storage
    [registry, proxy, guardian] = await deployAll(deployer);
  });

  async function initAndDeploy() {
    // process.exit();

    vault = await deployContract("VaultMock", deployer.address);
    await vault.init(registry.address, guardian.address, proxy.address);

    factory = await deployContractUpgradeable("VaultFactoryMock", [vault.address]);

    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin", deployer.address);
    usdt = await deployContract("TetherUSD", deployer.address);

    await usdc.mint(bob.address, normalize("900"));
    await usdc.mint(fred.address, normalize("900"));
    await usdc.mint(alice.address, normalize("900"));
    await usdt.mint(alice.address, normalize("600", 6));
    await usdc.mint(mike.address, normalize("600"));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
    ts = (await getTimestamp()) - 100;
  }

  describe("Buy vaults", function () {
    //here we test the contract
    beforeEach(async function () {
      await initAndDeploy();
    });

    it("should buy a vault", async function () {
      let price = await factory.finalPrice(usdc.address);
      await usdc.connect(bob).approve(factory.address, price);
      const nextTokenId = await vault.nextTokenId();
      const precalculatedAddress = await vault.managerOf(nextTokenId);
      await expect(factory.connect(bob).buyVaults(usdc.address, 1, true))
        .to.emit(vault, "Transfer")
        .withArgs(addr0, bob.address, nextTokenId)
        .to.emit(registry, "BoundContractCreated")
        .withArgs(
          precalculatedAddress,
          toChecksumAddress(proxy.address),
          "0x" + "0".repeat(64),
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

      await expect(factory.connect(fred).buyVaults(usdc.address, 1, true)).to.be.revertedWith("EnforcedPause");

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
      let nextTokenId = await vault.nextTokenId();
      await buyVault(usdc, 2, bob);
      await buyVault(usdt, 2, alice);
      expect(await vault.isActive(nextTokenId)).to.be.true;

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

    it.skip("should allow bob to purchase some vaults without activating them", async function () {
      let nextTokenId = await vault.nextTokenId();
      await buyVault(usdc, 2, bob, false);

      expect(await vault.isActive(nextTokenId)).to.be.false;

      const precalculatedAddress = await vault.managerOf(nextTokenId);
      // console.log(keccak256("BoundContractCreated(address,address,bytes32,uint256,address,uint256)"))

      await expect(vault.connect(bob).activate(nextTokenId))
        .to.emit(registry, "BoundContractCreated")
        .withArgs(
          precalculatedAddress,
          toChecksumAddress(proxy.address),
          "0x" + "0".repeat(64),
          (await getChainId()).toString(),
          toChecksumAddress(vault.address),
          nextTokenId,
        );
      expect(await vault.isActive(nextTokenId)).to.be.true;
    });

    it("should allow bob and alice to purchase some vaults with a discount", async function () {
      await factory.setDiscount(100);
      await vault.setMaxTokenId(100);
      expect(await vault.maxTokenId()).equal(100);

      await buyVault(usdc, 2, bob);
      await buyVault(usdt, 2, alice);

      let price = await factory.finalPrice(usdc.address);
      expect(price.toString()).to.equal("8900000000000000000");
      price = await factory.finalPrice(usdt.address);
      expect(price.toString()).to.equal("8900000");
    });

    it("should fail if max supply reached", async function () {
      await factory.setDiscount(100);

      await buyVault(usdc, 2, bob);
      await vault.setMaxTokenId(0);
      expect(await vault.maxTokenId()).equal(2);

      await expect(buyVault(usdt, 2, alice)).revertedWith("MaxSupplyReached");
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

  });
  async function expectedUsedGas(account, amount) {
    const initialBalance = (await vault.balanceOf(account.address)).toNumber() - amount;
    // it is 1 because we execute it after the minting
    return 86000 + (initialBalance === 0 ? 60000 : 0) + 105000 * amount + (amount < 3 ? 10000 : 0);
  }

  async function verifyGas(gasUsed, account, amount) {
    gasUsed = gasUsed.div(1e9).toNumber();
    const expected = await expectedUsedGas(account, amount);
    // console.log("gasUsed", gasUsed, "expected", expected);
    expect(gasUsed < expected + 10000).to.be.true;
  }

  describe("Used gas during purchases", function () {
    beforeEach(async function () {
      await initAndDeploy();
    });

    it("should verify gasLimit for batch buy vaults", async function () {
      const stableCoin = usdc.address;
      let pricePerVault = await factory.finalPrice(stableCoin);
      await usdc.connect(mike).approve(factory.address, pricePerVault.mul(100));

      // the first call must add 60000 gas, needed to set up the account
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [1], true)),
        mike,
        1,
      );
      // any successive call is much cheaper
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [1], true)),
        mike,
        1,
      );

      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [2], true)),
        mike,
        2,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [3], true)),
        mike,
        3,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [4], true)),
        mike,
        4,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [5], true)),
        mike,
        5,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [6], true)),
        mike,
        6,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [7], true)),
        mike,
        7,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [8], true)),
        mike,
        8,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [9], true)),
        mike,
        9,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [10], true)),
        mike,
        10,
      );
    });

    it("should verify gasLimit for batch buy vaults", async function () {
      const stableCoin = usdc.address;
      let pricePerVault = await factory.finalPrice(stableCoin);
      await usdc.connect(mike).approve(factory.address, pricePerVault.mul(100));

      // the first call must add 60000 gas, needed to set up the account
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 1, true)), mike, 1);
      // any successive call is much cheaper
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 1, true)), mike, 1);

      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 2, true)), mike, 2);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 3, true)), mike, 3);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 4, true)), mike, 4);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 5, true)), mike, 5);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 6, true)), mike, 6);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 7, true)), mike, 7);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 8, true)), mike, 8);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 9, true)), mike, 9);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 10, true)), mike, 10);
    });

    it("should verify gasLimit for batch buy vaults", async function () {
      const stableCoin = usdc.address;
      let pricePerVault = await factory.finalPrice(stableCoin);
      await usdc.connect(mike).approve(factory.address, pricePerVault.mul(100));

      // the first call must add 60000 gas, needed to set up the account
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [5], true)),
        mike,
        5,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [5], true)),
        mike,
        5,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [18], true)),
        mike,
        18,
      );
    });

    it("should verify gasLimit for batch buy vaults", async function () {
      const stableCoin = usdc.address;
      let pricePerVault = await factory.finalPrice(stableCoin);
      await usdc.connect(mike).approve(factory.address, pricePerVault.mul(100));

      // the first call must add 60000 gas, needed to set up the account
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [20], true)),
        mike,
        20,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [1], true)),
        mike,
        1,
      );
      await verifyGas(
        await executeAndReturnGasCost(factory.connect(mike).buyVaultsBatch(stableCoin, [mike.address], [1], true)),
        mike,
        1,
      );
    });

    async function expectedUsedGasNoActivation(account, amount) {
      const initialBalance = (await vault.balanceOf(account.address)).toNumber() - amount;
      // it is 1 because we execute it after the minting
      return (initialBalance === 0 ? 60000 : 0) + 30000 * amount + (amount === 1 ? 90000 : 80000);
    }

    async function verifyGasNoActivations(gasUsed, account, amount) {
      gasUsed = gasUsed.div(1e9).toNumber();
      const expected = await expectedUsedGasNoActivation(account, amount);
      expect(gasUsed < expected + 10000).to.be.true;
    }

    it("should verify gasLimit for batch buy vaults", async function () {
      const stableCoin = usdc.address;
      let pricePerVault = await factory.finalPrice(stableCoin);
      await usdc.connect(mike).approve(factory.address, pricePerVault.mul(100));

      // the first call must add 60000 gas, needed to set up the account
      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 1, false)),
        mike,
        1,
      );
      // any successive call is much cheaper
      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 1, false)),
        mike,
        1,
      );

      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 2, false)),
        mike,
        2,
      );
      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 3, false)),
        mike,
        3,
      );
      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 4, false)),
        mike,
        4,
      );
      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 5, false)),
        mike,
        5,
      );
      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 6, false)),
        mike,
        6,
      );
      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 7, false)),
        mike,
        7,
      );
      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 8, false)),
        mike,
        8,
      );
      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 9, false)),
        mike,
        9,
      );
      await verifyGasNoActivations(
        await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 10, false)),
        mike,
        10,
      );
    });
  });
});
