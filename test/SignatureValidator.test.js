const {expect} = require("chai");
const {ethers} = require("hardhat");
const DeployUtils = require("../scripts/lib/DeployUtils");
let deployUtils;
const helpers = require("./helpers");
const {getTimestamp} = require("./helpers");
const {domainType} = require("./helpers/eip712");
helpers.initEthers(ethers);
const {privateKeyByWallet, deployContract, getChainId, makeSignature} = helpers;

describe("SignatureValidator", function () {
  deployUtils = new DeployUtils(ethers);

  let chainId;

  let validator;
  let mailTo;
  let wallet;
  let protector;
  const name = "Cruna";
  const version = "1";

  before(async function () {
    [mailTo, wallet, tokenOwner, protector] = await ethers.getSigners();
    chainId = await getChainId();
  });

  beforeEach(async function () {
    validator = await deployContract("SignatureValidator", name, version);
  });

  it("should recover the signer of a recoverSigner2", async function () {
    const message = {
      address1: tokenOwner.address,
      address2: protector.address,
      integer1: 1,
      integer2: 19928273,
      timestamp: (await getTimestamp()) - 100,
      validFor: 3600,
    };

    const signature = await makeSignature(
      chainId,
      validator.target,
      privateKeyByWallet[protector.address],
      "Auth",
      [
        {name: "address1", type: "address"},
        {name: "address2", type: "address"},
        {name: "integer1", type: "uint256"},
        {name: "integer2", type: "uint256"},
        {name: "timestamp", type: "uint256"},
        {name: "validFor", type: "uint256"},
      ],
      message
    );

    expect(
      await validator.recoverSigner2(
        message.address1,
        message.address2,
        message.integer1,
        message.integer2,
        message.timestamp,
        message.validFor,
        signature
      )
    ).equal(protector.address);
  });

  it("should recover the signer of a recoverSigner3", async function () {
    const message = {
      address1: tokenOwner.address,
      address2: protector.address,
      address3: ethers.ZeroAddress,
      integer1: 1,
      integer2: 19928273,
      integer3: 0,
      timestamp: (await getTimestamp()) - 100,
      validFor: 3600,
    };

    const signature = await makeSignature(
      chainId,
      validator.target,
      privateKeyByWallet[protector.address],
      "Auth",
      [
        {name: "address1", type: "address"},
        {name: "address2", type: "address"},
        {name: "address3", type: "address"},
        {name: "integer1", type: "uint256"},
        {name: "integer2", type: "uint256"},
        {name: "integer3", type: "uint256"},
        {name: "timestamp", type: "uint256"},
        {name: "validFor", type: "uint256"},
      ],
      message
    );

    expect(
      await validator.recoverSigner3(
        message.address1,
        message.address2,
        message.address3,
        message.integer1,
        message.integer2,
        message.integer3,
        message.timestamp,
        message.validFor,
        signature
      )
    ).equal(protector.address);
  });
});
