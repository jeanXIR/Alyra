// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting is Ownable {

    /// DEFINITION DES VARIABLES
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {RegisteringVoters, ProposalsRegistrationStarted, ProposalsRegistrationEnded,
        VotingSessionStarted, VotingSessionEnded, VotesTallied}

    WorkflowStatus public status;
   
    mapping(address => Voter) public voters; // mapping des voters
    Proposal[] public proposals; // array des propositions
    uint nb_proposals = 0;
    

    /// DEFINITION DES EVENTS
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);


    /// DEFINITION DES FONCTIONS
    function set_status(WorkflowStatus _status) external onlyOwner{
        require(uint(_status) == uint(status) + 1, "suivez les etapes"); // on avance pas à pas dans les différents états du vote
        WorkflowStatus previousStatus = status;
        status = _status;
        WorkflowStatus newStatus = status;
        emit WorkflowStatusChange(previousStatus, newStatus);
    }

    function create_whitelist(address[] memory whitelisted_addresses) external onlyOwner{
        require(WorkflowStatus.RegisteringVoters == status, "ce n est pas la session d enrengistrement des votants");
        for (uint i = 0; i < whitelisted_addresses.length; i++) {
            voters[whitelisted_addresses[i]].isRegistered = true;
            emit VoterRegistered(whitelisted_addresses[i]); 
        }
    }

    function add_to_proposals(string memory _description) external {
        require(voters[msg.sender].isRegistered, "vous n etes pas whiteliste !!!");
        require(WorkflowStatus.ProposalsRegistrationStarted == status, "ce n est pas la session d enregistrement des propositions");
        proposals.push(Proposal(_description, 0));
        nb_proposals += 1;
        emit ProposalRegistered(nb_proposals);
    }


    function vote(uint proposalId) external {
        require(voters[msg.sender].isRegistered, "vous n etes pas whiteliste");
        require(!voters[msg.sender].hasVoted, "vous avez deja vote");
        require(WorkflowStatus.VotingSessionStarted == status, "ce n est pas la session de vote");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;
        emit Voted(msg.sender, proposalId);
        
        proposals[proposalId].voteCount += 1;
    }

    function getWinner() public view returns (uint winningProposal_) {
        require(WorkflowStatus.VotesTallied == status, "le depouillement des votes n a pas encore eu lieu");
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (string memory winnerName_) {
        require(WorkflowStatus.VotesTallied == status, "le depouillement des votes n a pas encore eu lieu");
        winnerName_ = proposals[getWinner()].description;
    }
}