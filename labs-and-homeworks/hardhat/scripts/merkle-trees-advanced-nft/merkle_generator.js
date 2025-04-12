const MerkleTreeGenerator = require('../../js_helpers/MerkleTreeGenerator.js');
const {ethers} = require('hardhat');
const fs = require('fs');

const participants = [
    "0x0000000000000000000000000000000000000001",
    "0x0000000000000000000000000000000000000002",
    "0x0000000000000000000000000000000000000003",
    "0x0000000000000000000000000000000000000004",
    "0x0000000000000000000000000000000000000005",
    "0x0000000000000000000000000000000000000006",
    "0x0000000000000000000000000000000000000007",
    "0x0000000000000000000000000000000000000008",
    "0x0000000000000000000000000000000000000009",
    "0x000000000000000000000000000000000000000A",
];

const filename = "participants_merkle_tree.json";

const merkleTreeGenerator = new MerkleTreeGenerator(participants);

merkleTreeGenerator.saveToFile(filename);
const verificationResult = merkleTreeGenerator.verify(ethers.keccak256(participants[0]), merkleTreeGenerator.getProof(ethers.keccak256(participants[0])));
console.log("Verification : ", verificationResult ? "Valid" : "Invalid");


