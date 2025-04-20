const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");

const whitelist = JSON.parse(fs.readFileSync("whitelist_data.json", "utf-8"));

const values = whitelist.participants.map((item) => 
  [item.index, item.address],
);

const tree = StandardMerkleTree.of(values, ["uint256", "address"]);

const root = tree.root;

const merkleData = {};
const proofs = [];


for (const [i, v] of tree.entries()) { {
      const proof = tree.getProof(i);
        proofs.push({
          index: v[0],
          address: v[1],
          proof: proof,
        });
    }
}

merkleData.root = root;
merkleData.proofs = proofs;

fs.writeFileSync("merkle.json", JSON.stringify(merkleData, null, 2), "utf-8");