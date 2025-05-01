// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {VotingLogicV1, InvalidProposalId, ProposalExecuted, InsufficientVotes, Proposal} from "./VotingLogicV1.sol";

contract VotingLogicV2 is VotingLogicV1 {
    

    function quorum() public pure returns (uint256) {
        return 1000; 
    }

    function executeProposal(uint256 proposalId) external override returns (bool) {
        if(proposalId > proposalCount) revert InvalidProposalId();

        Proposal storage proposal = proposals[proposalId];
        if(proposal.executed) revert ProposalExecuted();

        if(proposal.forVotes < quorum()) revert InsufficientVotes();

        proposal.executed = true;

        return proposal.executed;
    }
}