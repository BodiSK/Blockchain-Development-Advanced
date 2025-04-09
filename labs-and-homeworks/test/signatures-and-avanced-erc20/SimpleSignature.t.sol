// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {SimpleSignature} from "../../src/signatures-and-advanced-erc20/SimpleSignature.sol";


contract SimpleSignatureTest is Test {
    SimpleSignature simpleSignature;
    uint256 ownerPrivateKey = 1;
    address owner = vm.addr(ownerPrivateKey);

    function setUp() public {
        simpleSignature = new SimpleSignature();
    }

    function testVerifySignature() public view{
        bytes memory message = "Test message";

        bytes32 hash = keccak256(
            abi.encodePacked(message)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);
        address recovered = simpleSignature.verifySignature (
            message,
            v,
            r,
            s
        );

        assertEq(recovered, owner, "Signature verification failed");

    }
}