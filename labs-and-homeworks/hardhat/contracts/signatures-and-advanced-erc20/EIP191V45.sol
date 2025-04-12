// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


contract EIP191v45 {
    string public constant PREPEND = "\x19Ethereum Signed Message:\n32";

    function verifySignature(
        string calldata data, 
        uint8 v, 
        bytes32 r, 
        bytes32 s) public pure returns(address) {
            bytes32 hashedRawData = keccak256(bytes(data));

            bytes32 hashedData = keccak256(
                abi.encodePacked(PREPEND, hashedRawData)
            );

            address signer = ecrecover(hashedData, v, r, s);
            require(signer != address(0), "Invalid signature");
            return signer;
        }
   
}
