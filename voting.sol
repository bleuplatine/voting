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
    string[] allProposals;
    uint votes;
    Proposal[] winningProposalId;
    
    constructor() {
        whitelist.push(msg.sender);
        voters[msg.sender].isRegistered = true;
        proposals[0].voteCount = 0;
    }
  
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    
    struct Proposal {
        string description;
        uint voteCount;
    }
    
    mapping(address => Voter) voters;
    mapping(uint => Proposal) proposals;
    
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    
    modifier isInWhitelist() {
        require(voters[msg.sender].isRegistered == true, unicode"Vous n'êtes pas enregistré comme électeur");
        _;
    }
    
    // L'administrateur du vote commence et termine les différentes sessions.
    function setWorkflowStatus(WorkflowStatus _num) public onlyOwner {
        WorkflowStatus pnum = state;
        state = _num;
        emit WorkflowStatusChange(pnum, state);
    }
    
    // Afficher le statut actuel de la session de vote.
    function getWorkflowStatus() public view returns(WorkflowStatus) {
        return state;
    }
    
    // L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
    function addVoterToWhitelist(address _x) public onlyOwner {
        require(!voters[_x].isRegistered, unicode"Adresse déjà enregistrée");
        whitelist.push(_x);
        voters[_x].isRegistered = true;
        emit VoterRegistered(_x);
    }
    
    // Afficher la liste blanche d'électeurs inscrits.
    function getWhitelist() public view returns(address[] memory){
        return whitelist;
    }
    
    // Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.
    function addProposition(string memory _description) public isInWhitelist {
        require(state == WorkflowStatus.ProposalsRegistrationStarted, unicode"Session d'enregistrement des propositions inactive");
        ID++;
        proposals[ID].description = _description;
        emit ProposalRegistered(ID);
    }
    
    // Créer une liste des propositions enregistées.
    function setPropositions() public isInWhitelist {
        require(state != WorkflowStatus.RegisteringVoters && state != WorkflowStatus.ProposalsRegistrationStarted, unicode"Session d'enregistrement des propositions non termiée");
        for(uint i = 1; i <= ID; i++) {
            allProposals.push(proposals[i].description);
        }
    }
    
    // Afficher la liste des propositions enregistées.
    function getAllProposals() public view returns(string[] memory) {
        return allProposals;
    }
    
    // Les électeurs inscrits votent pour leurs propositions préférées.
    function vote(uint _proposalID) public isInWhitelist{
        require(state == WorkflowStatus.VotingSessionStarted, unicode"Session d'enregistrement des votes inactive");
        require(!voters[msg.sender].hasVoted, unicode"Déjà voté");
        require(_proposalID > 0 &&_proposalID <= ID, unicode"Proposition inconnue");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalID;
        proposals[_proposalID].voteCount++;
        votes++;
        emit Voted(msg.sender, _proposalID);
    }
    
    // L'administrateur du vote comptabilise les votes.
    function countAllVotes() public onlyOwner {
        require(state == WorkflowStatus.VotingSessionEnded, unicode"Session d'enregistrement des votes non termiée");
        uint winner = 0;
        for(uint i = 1; i <= ID; i++) {
            if(proposals[i].voteCount > proposals[i-1].voteCount) {
                winner = i;
            } 
        }
        winningProposalId.push(Proposal(proposals[winner].description, proposals[winner].voteCount));
        for(uint i = 1; i <= ID; i++) {
            if(i != winner && proposals[i].voteCount == proposals[winner].voteCount) {
                winningProposalId.push(Proposal(proposals[i].description, proposals[i].voteCount));
            } 
        }
        state = WorkflowStatus.VotesTallied;
    }
    
    // Retourner le(s) gagnant(s) - Tout le monde peut vérifier les derniers détails de la proposition gagnante.
    function getWinner() public view isInWhitelist returns(Proposal[] memory) {
        require(state == WorkflowStatus.VotesTallied, unicode"Les votes ne sont pas encore comptabilisés");
        return winningProposalId;
    }

}