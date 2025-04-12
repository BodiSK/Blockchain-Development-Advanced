const {MerkleTree} = require('merkletreejs');
const {ethers} = require ('hardhat');
const fs = require('fs');


const recipients = [
    {
        address: "0x0000000000000000000000000000000000000001",
        ammount: ethers.parseEther("0.1")
    },
    {
        address: "0x0000000000000000000000000000000000000002", // Fixed length
        ammount: ethers.parseEther("50")
    },
    {
        address: "0x0000000000000000000000000000000000000003",
        ammount: ethers.parseEther("100")
    },
    {
        address: "0x0000000000000000000000000000000000000004",
        ammount: ethers.parseEther("200")
    },
];


const leaves = recipients.map((recipient) => ethers.keccak256(
    ethers.solidityPacked(
        ["address", "uint256"],
        [recipient.address, recipient.ammount]
    )
));

const tree = new MerkleTree(leaves, ethers.keccak256, {sortPairs: true});

const root = tree.getHexRoot();
const rootHex = ethers.hexlify(root);

const proofs = leaves.map((x, index) => {
    return {
        address: recipients[index].address,
        ammount: recipients[index].ammount.toString(),
        proof: tree.getHexProof(x),
    }
});

const outpt = {
    root: rootHex,
    recipients: proofs,
}


fs.writeFileSync(
    "merke_data.json",
    JSON.stringify(outpt, null, 2)
);

