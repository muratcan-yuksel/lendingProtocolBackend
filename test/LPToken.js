const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

let token, owner, user1, lendingProtocolAddress, lendingProtocol;

beforeEach(async function () {
  // Deploy LPToken contract
  const Token = await ethers.getContractFactory("LPToken");
  token = await Token.deploy();
  // console.log("Token address:", await token.getAddress());
  const tokenAddress = await token.getAddress();

  // Deploy LendingProtocol contract
  const LendingProtocol = await ethers.getContractFactory("LendingProtocol");
  lendingProtocol = await LendingProtocol.deploy(tokenAddress);
  console.log("LendingProtocol address:", await lendingProtocol.getAddress());
  lendingProtocolAddress = await lendingProtocol.getAddress();

  // Get signers
  [owner, user1] = await ethers.getSigners();
});

it("Has correct name and symbol", async function () {
  expect(await token.name()).to.equal("LPToken");
  expect(await token.symbol()).to.equal("LPT");
});

it("mints 1000000 tokens to the deployer", async function () {
  //but convert them to wei also
  const balance = await token.balanceOf(owner.address);
  expect(balance).to.equal(ethers.parseEther("1000000"));

  //for the user1 now
  const balance1 = await token.balanceOf(user1.address);
  expect(balance1).to.equal(0);
});
