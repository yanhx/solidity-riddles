const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Overmint3"

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet] = await ethers.getSigners();

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy();
        const AttackerFactory = await ethers.getContractFactory("Overmint3Attcker");
        //const attackerContract = await AttackerFactory.deploy();

        return { victimContract, attackerWallet, AttackerFactory };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet, AttackerFactory;
        before(async function () {
            ({ victimContract, attackerWallet, AttackerFactory } = await loadFixture(setup));
        })

        it("conduct your attack here", async function () {
            await AttackerFactory.connect(attackerWallet).deploy(victimContract.address);
            // let tx = await AttackerFactory.connect(attackerWallet).deploy(victimContract.address);

            // let receipt = await tx.wait();
            // console.log(receipt.events?.filter((x) => {return x.event == "Transfer"}));
        });

        after(async function () {
            expect(await victimContract.balanceOf(attackerWallet.address)).to.be.equal(5);
            expect(await ethers.provider.getTransactionCount(attackerWallet.address)).to.equal(1, "must exploit one transaction");
        });
    });
});