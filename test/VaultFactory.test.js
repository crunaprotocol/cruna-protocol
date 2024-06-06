const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");
const EthDeployUtils = require("eth-deploy-utils");
const deployUtils = new EthDeployUtils();

const {
  cl,
  amount,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  executeAndReturnGasCost,
  signRequest,
  selectorId,
  deployCanonical,
  hasBeenDeployed,
} = require("./helpers");

describe.only("VaultFactory", function () {
  let crunaRegistry, proxy, guardian, erc6551Registry;
  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mike, proposer, executor;
  const delay = 10;
  let CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN;

  before(async function () {
    [deployer, proposer, executor, bob, alice, fred, mike] = await ethers.getSigners();
    [CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN] = await deployCanonical(deployer, proposer, executor, delay);
    crunaRegistry = await ethers.getContractAt("ERC7656Registry", CRUNA_REGISTRY);
    guardian = await ethers.getContractAt("CrunaGuardian", CRUNA_GUARDIAN);
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", ERC6551_REGISTRY);
  });

  async function initAndDeploy() {
    const managerImpl = await deployContract("CrunaManager");
    proxy = await deployContract("CrunaManagerProxy", managerImpl.address);
    proxy = await deployUtils.attach("CrunaManager", proxy.address);
    vault = await deployContract("OwnableNFT", deployer.address);

    await vault.init(proxy.address, true, 1, 0);
    factory = await deployContractUpgradeable("VaultFactory", [vault.address, deployer.address]);

    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin", deployer.address);
    usdt = await deployContract("TetherUSD", deployer.address);

    await usdc.mint(deployer.address, normalize("900"));
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
      await usdc.approve(factory.address, price);
      const nextTokenId = (await vault.nftConf()).nextTokenId;
      const precalculatedAddress = await vault.managerOf(nextTokenId);
      await expect(factory.buyVaultsAndActivateThem(usdc.address, 1))
        .to.emit(vault, "Transfer")
        .withArgs(addr0, deployer.address, nextTokenId)
        .to.emit(crunaRegistry, "Created")
        .withArgs(
          precalculatedAddress,
          toChecksumAddress(proxy.address),
          "0x" + "0".repeat(64),
          (await getChainId()).toString(),
          toChecksumAddress(vault.address),
          nextTokenId,
        );
    });

    async function buyVaults(token, amount, buyer, noActivation) {
      let price = await factory.finalPrice(token.address);
      await token.connect(buyer).approve(factory.address, price.mul(amount));
      let nextTokenId = (await vault.nftConf()).nextTokenId;
      let lastTokenId = nextTokenId.add(amount).sub(1);
      const e = expect(factory.connect(buyer)[noActivation ? "buyVaults" : "buyVaultsAndActivateThem"](token.address, amount))
        .to.emit(vault, "Transfer")
        .withArgs(addr0, buyer.address, nextTokenId)
        .to.emit(token, "Transfer")
        .withArgs(buyer.address, factory.address, price.mul(amount));
      if (amount > 1) {
        e.to.emit(vault, "Transfer").withArgs(addr0, buyer.address, lastTokenId);
      }
      if (!noActivation) {
        e.to.emit(vault, "ManagedActivatedFor").withArgs(nextTokenId, await vault.managerOf(nextTokenId));
        if (amount > 1) {
          e.to.emit(vault, "ManagedActivatedFor").withArgs(nextTokenId, await vault.managerOf(lastTokenId));
        }
      }
      await e;
    }

    it("should not allow bob and alice to purchase vaults when paused", async function () {
      await expect(factory.pause()).to.emit(factory, "Paused");
      let price = await factory.finalPrice(usdc.address);
      await usdc.connect(fred).approve(factory.address, price);

      await expect(factory.connect(fred).buyVaultsAndActivateThem(usdc.address, 1)).to.be.revertedWith("EnforcedPause");

      await expect(factory.unpause()).to.emit(factory, "Unpaused");

      await buyVaults(usdc, 2, bob);
      await buyVaults(usdt, 2, alice);

      price = await factory.finalPrice(usdc.address);
      await expect(price.toString()).to.equal("9900000000000000000");
      price = await factory.finalPrice(usdt.address);
      await expect(price.toString()).to.equal("9900000");

      await expect(factory.withdrawProceeds(fred.address, usdc.address, normalize("10")))
        .to.emit(usdc, "Transfer")
        .withArgs(factory.address, fred.address, normalize("10"));
      await expect(factory.withdrawProceeds(fred.address, usdc.address, 0))
        .to.emit(usdc, "Transfer")
        .withArgs(factory.address, fred.address, amount("9.8"));
    });

    it("should allow bob and alice to purchase some vaults", async function () {
      let nextTokenId = (await vault.nftConf()).nextTokenId;
      await buyVaults(usdc, 2, bob);
      await buyVaults(usdt, 2, alice);

      let price = await factory.finalPrice(usdc.address);
      await expect(price.toString()).to.equal("9900000000000000000");
      price = await factory.finalPrice(usdt.address);
      await expect(price.toString()).to.equal("9900000");

      await expect(factory.withdrawProceeds(fred.address, usdc.address, normalize("10")))
        .to.emit(usdc, "Transfer")
        .withArgs(factory.address, fred.address, normalize("10"));
      await expect(factory.withdrawProceeds(fred.address, usdc.address, 0))
        .to.emit(usdc, "Transfer")
        .withArgs(factory.address, fred.address, amount("9.8"));

      const managerAddress = await vault.managerOf(nextTokenId);
      const manager = await ethers.getContractAt("CrunaManager", managerAddress);

      const selector = await selectorId("ICrunaManager", "setProtector");
      const chainId = await getChainId();
      const ts = (await getTimestamp()) - 100;

      let signature = (
        await signRequest(
          selector,
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

      // set Alice as first Bob's protector
      if (process.env.IS_COVERAGE) {
        await expect(manager.connect(bob).setProtector(alice.address, true, ts, 3600, signature))
          .to.emit(manager, "ProtectorChange")
          .withArgs(alice.address, true);
      } else {
        await expect(manager.connect(bob).setProtector(alice.address, true, ts, 3600, signature))
          .to.emit(manager, "ProtectorChange")
          .withArgs(alice.address, true)
          .to.emit(vault, "Locked")
          .withArgs(nextTokenId, true);
      }
    });

    it("should allow bob and alice to purchase some vaults with a discount", async function () {
      await factory.setDiscount(100);
      await vault.setMaxTokenId(100);
      expect((await vault.nftConf()).maxTokenId).equal(100);

      await buyVaults(usdc, 2, bob);
      await buyVaults(usdt, 2, alice);

      let price = await factory.finalPrice(usdc.address);
      await expect(price.toString()).to.equal("8900000000000000000");
      price = await factory.finalPrice(usdt.address);
      await expect(price.toString()).to.equal("8900000");
    });

    it("should allow bob and alice to purchase some vaults activating them later", async function () {
      await factory.setDiscount(100);
      await vault.setMaxTokenId(100);
      expect((await vault.nftConf()).maxTokenId).equal(100);

      await buyVaults(usdc, 2, bob);
      await buyVaults(usdt, 2, alice, "NO_ACTIVATION");

      const man1 = await vault.managerOf(1);
      const man2 = await vault.managerOf(2);
      const man3 = await vault.managerOf(3);
      const man4 = await vault.managerOf(4);

      expect(await hasBeenDeployed(man1)).to.be.true;
      expect(await hasBeenDeployed(man2)).to.be.true;
      expect(await hasBeenDeployed(man3)).to.be.false;
      expect(await hasBeenDeployed(man4)).to.be.false;

      await expect(vault.activate(1)).to.be.revertedWith("NotTheTokenOwner");
      await expect(vault.connect(bob).activate(1)).to.be.revertedWith("AlreadyActivated").withArgs(1);
      await expect(vault.connect(alice).activate(3)).to.emit(vault, "ManagedActivatedFor").withArgs(3, man3);
      expect(await hasBeenDeployed(man3)).to.be.true;
    });

    it("should fail if max supply reached", async function () {
      await factory.setDiscount(100);

      await buyVaults(usdc, 3, bob);
      await vault.setMaxTokenId(3);
      expect((await vault.nftConf()).maxTokenId).equal(3);

      await expect(buyVaults(usdt, 1, alice)).revertedWith("InvalidTokenId");
    });

    it("should remove a stableCoin when active is false", async function () {
      await expect(factory.setStableCoin(usdc.address, false)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, false);

      const updatedStableCoins = await factory.getStableCoins();
      await expect(updatedStableCoins).to.not.include(usdc.address);
    });
  });
  async function expectedUsedGas(account, amount, noActivation = false) {
    const initialBalance = (await vault.balanceOf(account.address)).toNumber() - amount;
    // it is 1 because we execute it after the minting
    return 86000 + (initialBalance === 0 ? 60000 : 0) + (noActivation ? 30000 : 105000) * amount + (amount < 3 ? 10000 : 0);
  }

  async function verifyGas(gasUsed, account, amount, noActivation) {
    gasUsed = gasUsed.div(1e9).toNumber();
    const expected = await expectedUsedGas(account, amount, noActivation);
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
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 1)), mike, 1);
      // any successive call is much cheaper
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 1)), mike, 1);

      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 2)), mike, 2);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 3)), mike, 3);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 4)), mike, 4);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 5)), mike, 5);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 6)), mike, 6);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 7)), mike, 7);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 8)), mike, 8);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 9)), mike, 9);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaultsAndActivateThem(stableCoin, 10)), mike, 10);
    });

    it("should verify gasLimit for batch buy vaults", async function () {
      const stableCoin = usdc.address;
      let pricePerVault = await factory.finalPrice(stableCoin);
      await usdc.connect(mike).approve(factory.address, pricePerVault.mul(100));

      // the first call must add 60000 gas, needed to set up the account
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 1)), mike, 1, true);
      // any successive call is much cheaper
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 1)), mike, 1, true);

      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 2)), mike, 2, true);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 3)), mike, 3, true);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 4)), mike, 4, true);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 5)), mike, 5, true);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 6)), mike, 6, true);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 7)), mike, 7, true);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 8)), mike, 8, true);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 9)), mike, 9, true);
      await verifyGas(await executeAndReturnGasCost(factory.connect(mike).buyVaults(stableCoin, 10)), mike, 10, true);
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
  });
});
