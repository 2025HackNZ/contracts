# DAO Smart Contract

A decentralized autonomous organization (DAO) smart contract that implements quadratic voting and ETH-based membership. This contract allows members to create proposals, vote on them, and execute approved proposals.

## Features

- ETH-based membership system
- Quadratic voting mechanism
- Proposal creation and execution
- Time-bound voting periods
- Member deposit tracking

## Contract Parameters

- `minimumDeposit`: Minimum ETH amount required to become a member
- `votingPeriod`: Duration of the voting period in days (set during contract deployment)
- `totalDeposits`: Total ETH deposited in the DAO

## Core Functions

### Membership

#### `deposit()`
- Allows users to become members by depositing ETH
- Requirements:
  - Deposit amount must be >= `minimumDeposit`
- Tracks individual deposit amounts and join dates
- Updates `totalDeposits`

### Proposals

#### `createProposal(string description, uint256 amount, address payable target)`
- Creates a new proposal for transferring ETH
- Parameters:
  - `description`: Proposal description
  - `amount`: Amount of ETH to transfer
  - `target`: Recipient address for the ETH transfer
- Requirements:
  - Amount must be > 0
  - Target address must be valid (non-zero)

#### `vote(uint256 proposalId)`
- Allows members to vote on proposals using quadratic voting
- Voting power = square root of member's deposit amount
- Requirements:
  - Must be a member (have deposited ETH)
  - Cannot vote twice on the same proposal
  - Proposal must not be executed
  - Must be within voting period

#### `executeProposal(uint256 proposalId)`
- Executes approved proposals
- Requirements:
  - Voting period must have ended
  - Proposal must not be already executed
  - Must have > 51% of total possible quadratic voting power
  - DAO must have sufficient balance for the transfer
  - Transfer must succeed

## View Functions

### `getProposal(uint256 proposalId)`
Returns proposal details:
- Description
- Current yes votes (quadratic)
- End time
- Execution status
- Proposed amount
- Target address

### `getMemberInfo(address member)`
Returns member information:
- Deposit amount
- Join timestamp

## Events

- `ProposalCreated(uint256 indexed proposalId, string description, uint256 endTime)`
- `Voted(uint256 indexed proposalId, address indexed voter, bool support)`
- `ProposalExecuted(uint256 indexed proposalId)`
- `Deposited(address indexed member, uint256 amount)`

## Limitations and Considerations

1. **Single Vote Type**: Only supports yes votes; no option for negative voting
2. **No Withdrawal Mechanism**: Members cannot withdraw their deposits
3. **No Proposal Cancellation**: Once created, proposals cannot be cancelled
4. **Single Transfer Actions**: Proposals can only execute ETH transfers (no complex actions)
5. **Admin Controls**: Currently has admin-only proposal creation (needs access control implementation)
6. **Balance Management**: `totalDeposits` should be carefully managed during proposal execution

## Security Considerations

1. **Reentrancy**: Implements checks-effects-interactions pattern in `executeProposal`
2. **Integer Overflow**: Uses Solidity 0.8.13+ which includes built-in overflow checks
3. **Access Control**: Needs implementation for admin functions
4. **Voting Power**: Quadratic voting helps prevent wealth concentration in voting power

## Setup

1. Deploy the contract with:
   - `_minimumDeposit`: Minimum ETH required for membership
   - `_votingPeriodInDays`: Duration of voting periods

## Usage Example

```solidity
// Deploy
DAO dao = new DAO(1 ether, 7); // 1 ETH minimum, 7 days voting period

// Become a member
dao.deposit{value: 1 ether}();

// Create proposal
dao.createProposal("Fund Project X", 0.5 ether, recipientAddress);

// Vote on proposal
dao.vote(0);

// Execute proposal (after voting period)
dao.executeProposal(0);
```

## License

MIT License
```
