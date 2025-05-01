// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {VotingLogicV1} from "src/upgradeability/VotingLogicV1.sol";
import {VotingLogicV2} from "src/upgradeability/VotingLogicV2.sol";
import {console} from "forge-std/console.sol";


contract VotingSystemTest is Test {
    VotingLogicV1 public votingLogicV1;
    VotingLogicV2 public votingLogicV2;

    function setUp() public {
        votingLogicV1 = new VotingLogicV1();
        votingLogicV2 = new VotingLogicV2();
    }


    function test_TransparentProxyUpgrade() public {

        //1. Deploy the VotingLogicV1 contract and initialize it
        address proxy = Upgrades.deployTransparentProxy(
            "VotingLogicV1.sol",
            msg.sender,
            abi.encodeCall(VotingLogicV1.initialize, ())
        );

        VotingLogicV1 votingProxy = VotingLogicV1(proxy);

        //2. Create a proposal using the proxy contract
        votingProxy.createProposal("Proposal 1");

        //3. Vote on the proposal using the proxy contract
        for (uint256 i = 0; i < 1000; i++) {
            address voter = address(uint160(i + 1));
            vm.prank(voter);
            votingProxy.vote(1, true);
        }


        address implementation = Upgrades.getImplementationAddress(proxy);
        console.log("Implementation address: ", implementation);

        address admin = Upgrades.getAdminAddress(proxy);
        console.log("Admin address: ", admin);

        //4. Upgrade the proxy contract to VotingLogicV2
        //Upgrades.upgradeProxy(proxy,  "VotingLogicV2.sol", "", msg.sender);

        address newImplementation = Upgrades.getImplementationAddress(proxy);
        console.log("New implementation address: ", newImplementation);

        bool execute = votingProxy.executeProposal(1);
        assertTrue(execute, "Proposal execution failed");

    }
}