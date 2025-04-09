// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {console} from "forge-std/console.sol";


contract EIP191V0 {
    bytes1 public constant PREFIX = 0x19;
    bytes1 public constant VERSION = 0x00;
    
    function verifySignature(
        bytes memory data, 
        uint256 nonce, 
        uint8 v, 
        bytes32 r, 
        bytes32 s) public view returns(address) {
            bytes32 hashedData = keccak256(
                abi.encodePacked(
                    PREFIX,
                    VERSION,
                    address(this),
                    data,
                    nonce
                )
            );

            

            address signer = ecrecover(hashedData, v, r, s);
            require(signer != address(0), "Invalid signature");
            console.logBytes32( hashedData);

            return signer;

        }

   
}