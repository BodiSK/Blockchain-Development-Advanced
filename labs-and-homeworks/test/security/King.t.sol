// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {King} from "../../src/security-in-smart-contract-development/King.sol";
import {Attack} from "../../src/security-in-smart-contract-development/King.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract TestAttack is Test {

    King king;
    Attack attack;
    uint256 prize = 1 ether;
    address kingContractOwner;
    address attacker;

    function setUp() public {
        kingContractOwner = makeAddr("KingContractOwner");
        attacker = makeAddr("Attacker");

        vm.deal(kingContractOwner, prize);
        vm.prank(kingContractOwner);
        king = new King{value: prize}();

        vm.deal(attacker, prize);
        vm.prank(attacker);
        attack = new Attack{value: prize}(payable(address(king)));
    }

    function test_Attack() public {
        console.log("King: ", king._king());
        
        vm.startPrank(kingContractOwner);
        address(king).call{value: prize}("");
        vm.stopPrank();
        console.log("King: ", king._king());
    }

}