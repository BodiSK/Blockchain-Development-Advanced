// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Test} from "forge-std/Test.sol";
import {AdvancedToken} from "../../src/signatures-and-advanced-erc20/AdvancedToken.sol";
import {AuthorizationExpired} from "../../src/signatures-and-advanced-erc20/AdvancedToken.sol";
import {console} from "forge-std/console.sol";

contract AdvancedTokenTest is Test {
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 private constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        keccak256(
            "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
        );

    AdvancedToken token;
    uint256 signerPrivateKey = 1;
    address signer = vm.addr(signerPrivateKey);
    uint256 initialSupply = 1000 * 10 ** 18;
    uint256 initailAllocation = 100 * 10 ** 18;


    address deployer;
    address spender;

    function setUp() public {
        deployer = address(this);
        token = new AdvancedToken("AdvancedToken", "ATK", initialSupply);
        spender = makeAddr("spender");

        vm.deal(signer, 1 ether);

        token.transfer(signer, initailAllocation);

    }


    function test_Permit() public {
        uint256 nonce = token.nonces(signer);
        uint256 deadline = block.timestamp + 1 days;

        bytes32 digest = _getPermiDigest(
            signer,
            spender,
            initailAllocation,
            nonce,
            deadline
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        token.permit(signer, spender, initailAllocation, deadline, v, r, s);

        assertEq(token.allowance(signer, spender), initailAllocation);
    }


    function test_RevertIf_InvalidDeadline() public {
        console.log("Here 1");
        uint256 nonce = token.nonces(signer);
        console.log("Here 2");
        uint256 deadline = block.timestamp - 1 seconds;
        console.log("Here 3");

        bytes32 digest = _getPermiDigest(
            signer,
            spender,
            initailAllocation,
            nonce,
            deadline
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.expectRevert(abi.encodeWithSignature("ERC2612ExpiredSignature(uint256)", deadline));
        token.permit(signer, spender, initailAllocation, deadline, v, r, s);
    }

    function test_TransferWithAuthorization() public {
        uint256 validAfter = block.timestamp;
        uint256 validBefore = block.timestamp + 1 days;
        bytes32 nonce = keccak256(abi.encodePacked("nonce"));
        uint256 value = 10 * 10 ** 18;

        bytes32 authorizationHash = _getAuthorizationHash(
            signer,
            spender,
            value,
            validAfter,
            validBefore,
            nonce
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, authorizationHash);

        token.transferWithAuthorization(
            signer,
            spender,
            value,
            validAfter,
            validBefore,
            nonce,
            v,
            r, 
            s
        );

        assertEq(token.balanceOf(signer), initailAllocation - value);
        assertEq(token.balanceOf(spender), value);
    }

    function _getPermiDigest(
        address from,
        address to,
        uint256 allocation,
        uint256 nonce,
        uint256 deadline
    ) private view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        from,
                        to,
                        allocation,
                        nonce,
                        deadline
                    )
                )
            )
        );
    }

    function _getAuthorizationHash(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce
    ) private view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
                        from,
                        to,
                        value,
                        validAfter,
                        validBefore,
                        nonce
                    )
                )
            )
        );
    }
}