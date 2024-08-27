const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TreasureHunt", function () {
  let TreasureHunt, treasureHunt, owner, player1, player2;

  beforeEach(async function () {
    TreasureHunt = await ethers.getContractFactory("TreasureHunt");
    [owner, player1, player2, ...addrs] = await ethers.getSigners();
    treasureHunt = await TreasureHunt.deploy();
    await treasureHunt.deployed();
  });

  it("should initialize with the correct owner and treasure position", async function () {
    expect(await treasureHunt.owner()).to.equal(owner.address);
    const treasurePosition = await treasureHunt.treasurePosition();
    expect(treasurePosition).to.be.at.least(0).and.to.be.below(100);
  });

  it("should allow a player to make a valid move", async function () {
    await treasureHunt.connect(player1).move(5, { value: ethers.utils.parseEther("0.01") });
    const player1Position = await treasureHunt.playerPositions(player1.address);
    expect(player1Position).to.equal(5);
  });

  it("should reject an invalid move to a non-adjacent position", async function () {
    await treasureHunt.connect(player1).move(5, { value: ethers.utils.parseEther("0.01") });
    await expect(
      treasureHunt.connect(player1).move(10, { value: ethers.utils.parseEther("0.01") })
    ).to.be.revertedWith("You can only move to adjacent positions.");
  });

  it("should move the treasure when the player moves to a multiple of 5", async function () {
    const initialTreasurePosition = await treasureHunt.treasurePosition();
    await treasureHunt.connect(player1).move(5, { value: ethers.utils.parseEther("0.01") });
    const newTreasurePosition = await treasureHunt.treasurePosition();
    expect(newTreasurePosition).to.not.equal(initialTreasurePosition);
  });

  it("should jump the treasure to a random position when the player moves to a prime number", async function () {
    const initialTreasurePosition = await treasureHunt.treasurePosition();
    await treasureHunt.connect(player1).move(7, { value: ethers.utils.parseEther("0.01") });
    const newTreasurePosition = await treasureHunt.treasurePosition();
    expect(newTreasurePosition).to.not.equal(initialTreasurePosition);
  });

  it("should declare the winner when a player finds the treasure", async function () {
    const initialTreasurePosition = await treasureHunt.treasurePosition();
    await treasureHunt.connect(player1).move(initialTreasurePosition, { value: ethers.utils.parseEther("0.01") });
    const winner = await treasureHunt.winner();
    expect(winner).to.equal(player1.address);
  });

  it("should allow the owner to reset the game after it ends", async function () {
    const initialTreasurePosition = await treasureHunt.treasurePosition();
    await treasureHunt.connect(player1).move(initialTreasurePosition, { value: ethers.utils.parseEther("0.01") });
    await treasureHunt.resetGame();
    const newTreasurePosition = await treasureHunt.treasurePosition();
    expect(newTreasurePosition).to.not.equal(initialTreasurePosition);
    const winner = await treasureHunt.winner();
    expect(winner).to.equal(ethers.constants.AddressZero);
  });
});
