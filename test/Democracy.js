const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Democracy";

describe(NAME, function () {
  async function setup() {
      const [owner, attackerWallet] = await ethers.getSigners();
      const value = ethers.utils.parseEther("1");

      const VictimFactory = await ethers.getContractFactory(NAME);
      const victimContract = await VictimFactory.deploy({ value });
      const AttackerFactory = await ethers.getContractFactory("DemocracyAttacker");
      const attackerContract = await AttackerFactory.deploy(victimContract.address);

      return { victimContract, attackerWallet, attackerContract };
  }

  describe("exploit", async function () {
      let victimContract, attackerWallet, attackerContract;
      before(async function () {
          ({ victimContract, attackerWallet, attackerContract } = await loadFixture(setup));
      })

      it("conduct your attack here", async function () {
        await attackerContract.connect(attackerWallet).attack();
        
      });

      after(async function () {
          const victimContractBalance = await ethers.provider.getBalance(victimContract.address);
          expect(victimContractBalance).to.be.equal('0');
      });
  });
});