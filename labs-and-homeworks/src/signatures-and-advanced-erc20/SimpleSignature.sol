// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract SimpleSignature {


    function verifySignature (
        bytes memory data, 
        uint8 v, 
        bytes32 r, 
        bytes32 s) 
    public pure returns(address) {
        bytes32 hash = keccak256(
            abi.encodePacked(data)
        );

        return ecrecover(hash, v, r, s);
    }
}