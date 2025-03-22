// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAO {
    IERC20 public immutable nzdd;  // Added: NZDD token contract

    struct Proposal {
        string description;
        uint256 yesVotes;
        uint256 endTime;
        bool executed;
        uint256 amount;        // Now represents NZDD amount
        address target;        // Removed payable since we're sending tokens
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

    constructor(
        address _nzddToken,
        uint256 _minimumDeposit, 
        uint256 _votingPeriodInDays
    ) {
        require(_nzddToken != address(0), "Invalid token address");
        nzdd = IERC20(_nzddToken);
        minimumDeposit = _minimumDeposit;
        votingPeriod = _votingPeriodInDays * 1 days;
    }

    // Deposit NZDD to become a member
    function deposit(uint256 amount) external {
        require(amount >= minimumDeposit, "Deposit amount too low");
        
        require(nzdd.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        members[msg.sender].depositAmount += amount;
        if (members[msg.sender].joinedAt == 0) {
            members[msg.sender].joinedAt = block.timestamp;
        }
        totalDeposits += amount;
        
        emit Deposited(msg.sender, amount);
    }

    // Create a new proposal
    function createProposal(
        string memory description, 
        uint256 amount,
        address target
    ) external {
        require(amount > 0, "Amount must be greater than 0");
        require(target != address(0), "Invalid target address");
        // require(amount <= nzdd.balanceOf(address(this)), "Amount exceeds DAO balance");
        
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

        uint256 totalVotingPower = sqrt(totalDeposits);
        if (proposal.yesVotes * 100 > totalVotingPower * 51 && proposal.amount <= nzdd.balanceOf(address(this)))
            {
                executeProposal(proposalId);
            }

        emit Voted(proposalId, msg.sender, true);
    }

    // Execute a proposal if it has passed
    function executeProposal(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        
        // require(block.timestamp >= proposal.endTime, "Voting period not ended");
        // require(!proposal.executed, "Proposal already executed");      
        //require(nzdd.balanceOf(address(this)) >= proposal.amount, "Insufficient DAO balance");

        proposal.executed = true;
        totalDeposits -= proposal.amount;
        require(nzdd.transfer(proposal.target, proposal.amount), "Transfer failed");

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