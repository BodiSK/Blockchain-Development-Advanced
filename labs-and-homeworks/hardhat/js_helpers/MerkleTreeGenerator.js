const { MerkleTree } = require("merkletreejs");
const { ethers } = require("hardhat");
const fs = require("fs");

class MerkleTreeGenerator {
  constructor(participants) {
    this.participants = participants;
    this.leaves = this.generateLeaves(participants);
    this.tree = this.generateTree(this.leaves);
    this.root = this.tree.getHexRoot();
  }

  generateLeaves(participants) {
    return participants.map((participant) => {
      return ethers.keccak256(participant);
    });
  }

  generateTree(leaves) {
    return new MerkleTree(leaves, ethers.keccak256, { sortPairs: true });
  }

  getRoot() {
    return this.root;
  }

  getProof(leaf) {
    return this.tree.getHexProof(leaf);
  }

  getLeaves() {
    return this.leaves;
  }

  verify(leaf, proof) {
    return this.tree.verify(proof, leaf, this.root);
  }

  saveToFile(filename) {

    const proofs = this.leaves.map((x, index) => {
        return {
            address: this.participants[index],
            proof: this.tree.getHexProof(x),
        }
    });

    const data = {
      root: this.root,
      proofs: proofs,
    };
    fs.writeFileSync(filename, JSON.stringify(data, null, 2));
  }
}


module.exports = MerkleTreeGenerator;
