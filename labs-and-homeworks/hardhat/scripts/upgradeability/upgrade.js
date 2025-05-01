const { ethers, upgrades } = require("hardhat");

async function main() {
  const TreasuryV2 = await ethers.getContractFactory("TreasuryV2");
  const treasury = await upgrades.upgradeProxy(
    "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    TreasuryV2
  );
  console.log("Tresury upgraded with v2");
}

main();
