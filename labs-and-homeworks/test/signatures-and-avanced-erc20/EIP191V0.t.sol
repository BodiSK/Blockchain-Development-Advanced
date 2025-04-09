// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {EIP191V0} from "../../src/signatures-and-advanced-erc20/EIP191V0.sol";


contract SimpleSignatureTest is Test {
    EIP191V0 verifier;
    uint256 ownerPrivateKey = 1;
    address owner = vm.addr(ownerPrivateKey);
    uint256 nonce = 1;

    bytes1 public constant PREFIX = 0x19;
    bytes1 public constant VERSION = 0x00;

    function setUp() public {
        verifier = new EIP191V0();
    }

    function testVerifySignature() public view{
        bytes memory message = "Test message";

        bytes32 hashed = keccak256(
            abi.encodePacked(
                PREFIX,
                VERSION,
                address(verifier),
                message,
                nonce
            )
        );

        console.logBytes32( hashed);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hashed);
        address recovered = verifier.verifySignature(
            message,
            nonce,
            v,
            r,
            s
        );

        assertEq(recovered, owner, "Signature verification failed");

    }
}