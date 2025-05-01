// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const TreasuryV1 = await ethers.getContractFactory("TreasuryV1");
  const treasury = await upgrades.deployProxy(
    TreasuryV1,
    ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "Treasury",
    "T1"]
  );
  await treasury.waitForDeployment();
  console.log("Treasury V1 deployed to:", await treasury.getAddress());
}

main();
