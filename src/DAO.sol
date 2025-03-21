// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract DAO {
    // ??? Access control
    struct Proposal {
        string description;
        uint256 yesVotes;
        uint256 endTime;
        bool executed;
        uint256 amount;        // Added: amount of ETH needed for proposal
        address payable target; // Added: target address for the transfer
        mapping(address => bool) hasVoted;
    }

    struct Member {
        uint256 depositAmount;
        uint256 joinedAt;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    
    uint256 public proposalCount;
    uint256 public minimumDeposit;
    uint256 public votingPeriod;
    uint256 public totalDeposits;

    event ProposalCreated(uint256 indexed proposalId, string description, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event Deposited(address indexed member, uint256 amount);

    constructor(uint256 _minimumDeposit, uint256 _votingPeriodInDays) {
        minimumDeposit = _minimumDeposit;
        votingPeriod = _votingPeriodInDays * 1 days;
    }

    // Deposit ETH to become a member
    function deposit() external payable {
        require(msg.value >= minimumDeposit, "Deposit amount too low");
        
        members[msg.sender].depositAmount += msg.value;
        if (members[msg.sender].joinedAt == 0) {
            members[msg.sender].joinedAt = block.timestamp;
        }
        totalDeposits += msg.value; // ?? we should confirm it gets updated after a proposal is executed
        
        emit Deposited(msg.sender, msg.value);
    }
// ??? Only DAO admin - no need for deposit amount check
    // Create a new proposal
    function createProposal(
        string memory description, 
        uint256 amount,
        address payable target
    ) external {
        //require(members[msg.sender].depositAmount > 0, "Not a member");
        require(amount > 0, "Amount must be greater than 0");
        //require(amount <= address(this).balance, "Amount exceeds DAO balance");
        require(target != address(0), "Invalid target address");
        
        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        
        proposal.description = description;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.amount = amount;
        proposal.target = target;
        
        emit ProposalCreated(proposalId, description, proposal.endTime);
    }

    // Add a library for square root calculation
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        
        return y;
    }

    // Modify vote function to use quadratic voting
    function vote(uint256 proposalId) external {
        require(members[msg.sender].depositAmount > 0, "Not an investor");
        
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp < proposal.endTime, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.executed, "Proposal already executed");

        proposal.hasVoted[msg.sender] = true;

        // Calculate quadratic voting power (square root of deposit)
        uint256 votingPower = sqrt(members[msg.sender].depositAmount);
        proposal.yesVotes += votingPower;

        emit Voted(proposalId, msg.sender, true);
    }

    // Execute a proposal if it has passed
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        
        // Calculate total possible voting power (sqrt of total deposits)
        uint256 totalVotingPower = sqrt(totalDeposits);
        // Require 51% of total possible voting power
        require(proposal.yesVotes * 100 > totalVotingPower * 51, "Insufficient votes");
        require(address(this).balance >= proposal.amount, "Insufficient DAO balance");

        proposal.executed = true;
        totalDeposits -= proposal.amount;
        (bool success, ) = proposal.target.call{value: proposal.amount}("");
        require(success, "Transfer failed");

        emit ProposalExecuted(proposalId);
    }

    // Update getProposal function to include amount and target
    function getProposal(uint256 proposalId) external view returns (
        string memory description,
        uint256 yesVotesQuadratic,
        uint256 endTime,
        bool executed,
        uint256 amount,
        address target
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.description,
            proposal.yesVotes,
            proposal.endTime,
            proposal.executed,
            proposal.amount,
            proposal.target
        );
    }

    function getMemberInfo(address member) external view returns (
        uint256 depositAmount,
        uint256 joinedAt
    ) {
        return (
            members[member].depositAmount,
            members[member].joinedAt
        );
    }
} 