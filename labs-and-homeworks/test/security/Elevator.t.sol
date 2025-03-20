// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Elevator} from "../../src/security-in-smart-contract-development/Elevator.sol";
import {Attack} from "../../src/security-in-smart-contract-development/Elevator.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract TestAttack is Test {
    Elevator elevator;
    Attack attack;  

    function setUp() public {
        elevator = new Elevator();
        attack = new Attack();
    }

    function test_Attack() public {
        attack.attack(address(elevator));
        console.log("Top: ", elevator.top());
    }
}