const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");
const { Contract } = require("@ethersproject/contracts");
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
  keccak256,
  bytes4,
  combineBytes4ToBytes32,
  getInterfaceId,
  selectorId,
  combineTimestampAndValidFor,
  deployCanonical,
  trustImplementation,

  setFakeCanonicalIfCoverage,
} = require("./helpers");

describe("CrunaManager : Protectors", function () {
  let crunaRegistry, proxy, managerImpl, guardian, validatorMock, erc6551Registry;

  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto, proposer, executor;
  let selector;
  let ts;
  // we put it very short for convenience (test-only)
  const delay = 10;
  let chainId;

  let CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN;

  before(async function () {
    [deployer, proposer, executor, bob, alice, fred, mark, otto] = await ethers.getSigners();
    chainId = await getChainId();
    selector = await selectorId("ICrunaManager", "setProtector");
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
    validatorMock = await deployContract("SignatureValidatorMock");

    usdc = await deployContract("USDCoin", deployer.address);
    usdt = await deployContract("TetherUSD", deployer.address);

    await usdc.mint(bob.address, normalize("900"));
    await usdt.mint(alice.address, normalize("600", 6));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
    ts = (await getTimestamp()) - 100;
  });

  const buyAVault = async (bob) => {
    const price = await factory.finalPrice(usdc.address);
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    const precalculatedAddress = await vault.managerOf(nextTokenId);

    // console.log(keccak256("TokenLinkedContractCreated(address,address,bytes32,uint256,address,uint256)"))

    await expect(factory.connect(bob).buyVaults(usdc.address, 1))
      .to.emit(crunaRegistry, "TokenLinkedContractCreated")
      .withArgs(
        precalculatedAddress,
        toChecksumAddress(proxy.address),
        "0x" + "0".repeat(64),
        (await getChainId()).toString(),
        toChecksumAddress(vault.address),
        nextTokenId,
      );

    const managerAddress = await vault.managerOf(nextTokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    return nextTokenId;
  };

  it("should fail if function not found in proxy", async function () {
    const fakeAbi = [
      {
        inputs: [
          {
            internalType: "bytes4",
            name: "role",
            type: "bytes4",
          },
        ],
        name: "bullish",
        outputs: [
          {
            internalType: "uint256",
            name: "",
            type: "uint256",
          },
        ],
        stateMutability: "view",
        type: "function",
      },
    ];

    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = new Contract(managerAddress, fakeAbi, ethers.provider);

    await expect(manager.bullish("0x12345678")).revertedWith("");
  });

  it("should verify CrunaManagerBase parameters", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    expect(await manager.version()).to.equal(1e6);
    expect(await manager.tokenId()).to.equal(tokenId);
    expect(await manager.tokenAddress()).to.equal(vault.address);
    expect(await manager.owner()).to.equal(bob.address);
    expect(await manager.token()).deep.equal([ethers.BigNumber.from(chainId.toString()), vault.address, tokenId]);
  });

  it("should verify vault base parameters", async function () {
    expect(await vault.defaultLocked()).to.be.false;
    const tokenId = await buyAVault(bob);
    expect(await vault.tokenURI(tokenId)).to.equal("https://meta.cruna.cc/vault/v1/31337/1");
    expect(await vault.contractURI()).to.equal("https://meta.cruna.cc/vault/v1/31337/info");
    expect(await vault.locked(tokenId)).to.be.false;
    expect(await vault.isTransferable(tokenId, bob.address, addr0)).to.be.false;
    expect(await vault.isTransferable(tokenId, bob.address, bob.address)).to.be.false;
    expect(await vault.isTransferable(tokenId, bob.address, fred.address)).to.be.true;
  });

  it("should add the first protector and remove it", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    expect(await vault.supportsInterface("0x80ac58cd")).to.equal(true);

    let signature = (
      await signRequest(
        selector,
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
    await expect(manager.connect(bob).setProtector(alice.address, true, ts, 3600, signature))
      .to.emit(manager, "ProtectorChange")
      .withArgs(alice.address, true)
      .to.emit(vault, "Locked")
      .withArgs(tokenId, true);

    await expect(manager.connect(bob).setProtector(alice.address, false, ts, 3600, signature)).to.be.revertedWith(
      "SignatureAlreadyUsed",
    );

    // set a second protector

    signature = (
      await signRequest(
        selector,
        bob.address,
        fred.address,
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

    await expect(manager.connect(bob).setProtector(fred.address, true, ts, 3600, signature))
      .to.emit(manager, "ProtectorChange")
      .withArgs(fred.address, true);

    // Alice removes herself as protector

    signature = (
      await signRequest(
        selector,
        bob.address,
        alice.address,
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

    await expect(manager.connect(bob).setProtector(alice.address, true, ts, 3600, signature)).to.be.revertedWith(
      "WrongDataOrNotSignedByProtector",
    );

    await expect(manager.connect(bob).setProtector(alice.address, false, ts, 3600, signature))
      .to.emit(manager, "ProtectorChange")
      .withArgs(alice.address, false);

    // set again alice with a preApproval

    const timeValidation = combineTimestampAndValidFor(ts, 3600).toString();

    let params = [selector, bob.address, alice.address, vault.address, tokenId, 1, 0, 0, timeValidation];

    let hash = await validatorMock.hashData(...params);

    await expect(manager.connect(fred).preApprove(...params))
      .to.emit(manager, "PreApproved")
      .withArgs(hash, fred.address);

    await expect(manager.connect(bob).setProtector(alice.address, true, ts, 3600, 0))
      .to.emit(manager, "ProtectorChange")
      .withArgs(alice.address, true);
  });

  it("should add the first protector via preApproval and remove it", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    expect(await vault.supportsInterface("0x80ac58cd")).to.equal(true);

    const timeValidation = combineTimestampAndValidFor(ts, 3600).toString();

    let params = [selector, bob.address, alice.address, vault.address, tokenId, 1, 0, 0, timeValidation];
    await expect(manager.connect(bob).preApprove(...params)).revertedWith("NotAuthorized");

    let hash = await validatorMock.hashData(...params);

    await expect(manager.connect(alice).preApprove(...params))
      .to.emit(manager, "PreApproved")
      .withArgs(hash, alice.address);

    await expect(manager.connect(bob).setProtector(alice.address, true, ts, 3600, 0))
      .to.emit(manager, "ProtectorChange")
      .withArgs(alice.address, true)
      .to.emit(vault, "Locked")
      .withArgs(tokenId, true);
  });

  it("should throw is wrong data for first protector", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    // set Alice as first Bob's protector
    await expect(manager.connect(bob).setProtector(addr0, true, 0, 0, 0)).revertedWith("ZeroAddress");
    await expect(manager.connect(bob).setProtector(bob.address, true, 0, 0, 0)).revertedWith("CannotBeYourself");
  });

  it("should add many protectors", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    expect(await manager.hasProtectors()).to.equal(false);

    let signature = (
      await signRequest(
        selector,
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

    // Set Fred as Bob's protector
    // To do so Bob needs Alice's signature

    let allProtectors = await manager.getProtectors();
    expect(allProtectors[0]).equal(alice.address);

    signature = (
      await signRequest(
        selector,
        bob.address,
        fred.address,
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

    await expect(manager.connect(bob).setProtector(fred.address, true, ts, 3600, signature))
      .to.emit(manager, "ProtectorChange")
      .withArgs(fred.address, true);

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
    signature = (
      await signRequest(
        selector,
        bob.address,
        alice.address,
        vault.address,
        tokenId,
        0,
        0,
        0,
        ts,
        3600,
        chainId,
        fred.address,
        manager,
      )
    )[0];

    await expect(manager.connect(bob).setProtector(alice.address, false, ts, 3600, signature))
      .to.emit(manager, "ProtectorChange")
      .withArgs(alice.address, false);

    expect(await manager.findProtectorIndex(fred.address)).to.equal(0);
  });

  it("should add a protector and transfer a vault", async function () {
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    let signature = (
      await signRequest(
        selector,
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

    await expect(
      vault.connect(bob)["safeTransferFrom(address,address,uint256)"](bob.address, fred.address, tokenId),
    ).to.be.revertedWith("NotTransferable");

    signature = (
      await signRequest(
        await selectorId("ICrunaManager", "protectedTransfer"),
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
        manager,
      )
    )[0];
    await expect(manager.connect(bob).protectedTransfer(tokenId, fred.address, ts, 3600, signature))
      .to.emit(manager, "Reset")
      .withArgs(tokenId)
      .to.emit(vault, "Transfer")
      .withArgs(bob.address, fred.address, tokenId);
  });
});
