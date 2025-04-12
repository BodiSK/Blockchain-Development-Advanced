// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


error InvalidProof();

contract MerkleVerificationContract is Ownable {
    bytes32 public  merkleRoot;

    event MerkleRootUpdated();


    constructor(bytes32 _merkleRoot, address _owner) Ownable(_owner) {
        merkleRoot = _merkleRoot;
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated();
    }

    function verify(bytes32[] calldata proof, bytes32 leaf) external view returns (bool) {
         if (!MerkleProof.verify(proof, merkleRoot, leaf)) {
            revert InvalidProof();
        }
        return true;
    }
    
}