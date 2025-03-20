// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Force} from "../../src/security-in-smart-contract-development/Force.sol";
import {Attack} from "../../src/security-in-smart-contract-development/Force.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract ForceAttackTest is Test{

    Force force;
    Attack attack;

    function setUp() public {
        force = new Force();
        attack = new Attack(address(force));
    }

    function test_Attack() public {
        console.log("Force balance before attack: ", address(force).balance);

        vm.deal(address(attack), 1 ether);
        attack.attack();

        console.log("Force balance after attack: ", address(force).balance);
    }

}