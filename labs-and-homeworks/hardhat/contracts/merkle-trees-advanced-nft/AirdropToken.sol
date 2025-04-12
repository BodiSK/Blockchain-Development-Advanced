// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error AlreadyClaimed();
error InvalidProof();

contract AirdropToken is ERC20 {
    bytes32 public immutable MERKLE_ROOT;
    mapping(address => bool) public isClaimed;

    event Claimed(address indexed account, uint256 amount);

    constructor(bytes32 _root) ERC20("Airdrop", "AD") {
        MERKLE_ROOT = _root;
    }

    function claim(uint256 amount, bytes32[] calldata proofs) external {
        if (isClaimed[msg.sender]) revert AlreadyClaimed();
        if (
            MerkleProof.verify(
                proofs,
                MERKLE_ROOT,
                keccak256(abi.encodePacked(msg.sender, amount))
            ) == false
        ) revert InvalidProof();

        isClaimed[msg.sender] = true;
        _mint(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }
}
