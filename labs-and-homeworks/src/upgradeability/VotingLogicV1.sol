// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

struct Proposal {
    uint256 id;
    address proposer;
    string description;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
}

error InvalidProposalId();
error ProposalExecuted();
error InsufficientVotes();

contract VotingLogicV1 is Initializable, OwnableUpgradeable {

    mapping (uint256 => Proposal) public proposals;
    uint256 internal proposalCount;

    constructor ()  {
        _disableInitializers();
    }

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }


    function createProposal(string calldata _description) external returns (uint256) {
        
        proposals[proposalCount++] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _description,
            forVotes: 0,
            againstVotes: 0,
            executed: false
        });

        return proposalCount;
    }

    function vote(uint256 proposalId, bool voteFor) external {
        if(proposalId > proposalCount) revert InvalidProposalId();

        Proposal storage proposal = proposals[proposalId];
        if(proposal.executed) revert ProposalExecuted();

        if(voteFor) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
    }

    function executeProposal(uint256 proposalId) external virtual returns (bool) {
        if(proposalId > proposalCount) revert InvalidProposalId();

        Proposal storage proposal = proposals[proposalId];
        if(proposal.executed) revert ProposalExecuted();

        if(proposal.forVotes > proposal.againstVotes) {
            proposal.executed = true;
        } 

        return proposal.executed;
    }
}

