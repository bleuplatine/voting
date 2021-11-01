// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    WorkflowStatus state;
    
    address[] whitelist;
    uint ID;
    Proposal[] allProposals;
  
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    
    struct Proposal {
        uint proposalID;
        string description;
        uint voteCount;
    }
    
    mapping(address => Voter) voters;
    mapping(address => Proposal) proposals;
    
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    
    modifier isInWhitelist() {
        require(voters[msg.sender].isRegistered == true, "Vous n'etes pas enregistre comme electeur");
        _;
    }
    
    function setWorkflowStatus(WorkflowStatus _num) public onlyOwner {
        WorkflowStatus pnum = state;
        state = _num;
        emit WorkflowStatusChange(pnum, state);
    }
    
    function getWorkflowStatus() public view returns(WorkflowStatus) {
        return state;
    }
    
    function addVoterToWhitelist(address _x) public onlyOwner {
        // vérifier adresse déjà enregistrée
        whitelist.push(_x);
        voters[_x].isRegistered = true;
        emit VoterRegistered(_x);
    }
    
    function addProposition(string memory _description) public isInWhitelist {
        require(state == WorkflowStatus.ProposalsRegistrationStarted, "Session d'enregistrement des propositions inactive");
        proposals[msg.sender].description = _description;
        proposals[msg.sender].proposalID = ID;
        emit ProposalRegistered(ID);
        allProposals.push(proposals[msg.sender]);
        ID++;
    }
    
    function getPropositions() public view isInWhitelist returns(Proposal[] memory) {
        require(state != WorkflowStatus.RegisteringVoters && state != WorkflowStatus.ProposalsRegistrationStarted, "Session d'enregistrement des propositions non termiee");
        return allProposals;
    }
    
    function vote(uint256 _proposalID) public isInWhitelist{
        require(state == WorkflowStatus.VotingSessionStarted, "Session d'enregistrement des votes inactive");
        require(!voters[msg.sender].hasVoted, "Deja vote");
        require(_proposalID > allProposals.length, "Proposition inconnue");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalID;
        allProposals[_proposalID].voteCount++;
    }
    
}