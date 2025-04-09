// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {Attack} from "../../src/security-in-smart-contract-development/DexTwo/DexTwoAttack.sol";
import {DexTwo} from "../../src/security-in-smart-contract-development/DexTwo/DexTwo.sol";
import {FakeToken} from "../../src/security-in-smart-contract-development/DexTwo/DexTwoAttack.sol";
import {SwappableTokenTwo} from "../../src/security-in-smart-contract-development/DexTwo/DexTwo.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract DexTwoAttackTest is Test {
    address dexOwner;
    address attacker;

    DexTwo dex;
    Attack attack;
    SwappableTokenTwo token1;
    SwappableTokenTwo token2;

    function setUp() public {
        dexOwner = makeAddr("DexOwner");
        attacker = makeAddr("Attacker");

        vm.startPrank(dexOwner);
        dex = new DexTwo();
        token1 = new SwappableTokenTwo(address(dex), "Token1", "T1", 1000);
        token2 = new SwappableTokenTwo(address(dex), "Token2", "T2", 1000);
        dex.setTokens(address(token1), address(token2));

        token1.approve(address(dex), 100);
        token2.approve(address(dex), 100);

        dex.add_liquidity(address(token1), 100);
        dex.add_liquidity(address(token2), 100);

        token1.transfer(address(attacker), 10);
        token2.transfer(address(attacker), 10);  
        vm.stopPrank();


        vm.startPrank(attacker);
        attack = new Attack(address(dex));
    }

    function test_Attack() public {
        
        console.log("Dex Initial balance token1: ",token1.balanceOf(address(dex)));
        console.log("Dex Initial balance token2: ",token2.balanceOf(address(dex)));
        console.log("Attacker Initial balance token1: ",token1.balanceOf(attacker));
        console.log("Attacker Initial balance token2: ",token2.balanceOf(attacker));


        vm.startPrank(attacker);
        attack.attack();
        vm.stopPrank();

        console.log("Dex balance after attack token1: ",token1.balanceOf(address(dex)));
        console.log("Dex balance after attack token2: ",token2.balanceOf(address(dex)));
        console.log("Attacker (contract) balance after attack token1: ",token1.balanceOf(address(attack)));
        console.log("Attacker (contract) balance after attack token2: ",token2.balanceOf(address(attack)));
    }
    
}
