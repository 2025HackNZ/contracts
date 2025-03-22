// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DAO.sol";

contract DAOTest is Test {
    DAO public dao;
    MockERC20 public nzdd;  // Added: Mock NZDD token
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    uint256 public constant MINIMUM_DEPOSIT = 1_000_000; // 1 NZDD
    uint256 public constant VOTING_PERIOD = 7; // 7 days

    function setUp() public {
        // Deploy mock NZDD token with 6 decimals
        nzdd = new MockERC20("New Zealand Digital Dollar", "NZDD", 6);
        dao = new DAO(address(nzdd), MINIMUM_DEPOSIT, VOTING_PERIOD);
        
        // Mint 10 NZDD to each test address
        nzdd.mint(alice, 10_000_000); // 10 NZDD
        nzdd.mint(bob, 10_000_000);   // 10 NZDD
        nzdd.mint(charlie, 10_000_000); // 10 NZDD
        
        vm.prank(alice);
        nzdd.approve(address(dao), type(uint256).max);
        vm.prank(bob);
        nzdd.approve(address(dao), type(uint256).max);
        vm.prank(charlie);
        nzdd.approve(address(dao), type(uint256).max);
    }

    function testDeposit() public {
        vm.prank(alice);
        dao.deposit(1_000_000); // 1 NZDD

        (uint256 depositAmount, uint256 joinedAt) = dao.getMemberInfo(alice);
        assertEq(depositAmount, 1_000_000);
        assertEq(joinedAt, block.timestamp);
        assertEq(dao.totalDeposits(), 1_000_000);
    }

    function test_RevertIf_DepositBelowMinimum() public {
        vm.prank(alice);
        vm.expectRevert();
        dao.deposit(500_000); // 0.5 NZDD
    }

    function testCreateProposal() public {
        uint256 proposalAmount = 0.5 ether;
        address payable target = payable(address(0x4));

        vm.prank(alice);
        dao.createProposal("Test Proposal", proposalAmount, target);

        (
            string memory description,
            uint256 yesVotes,
            uint256 endTime,
            bool executed,
            uint256 amount,
            address proposalTarget
        ) = dao.getProposal(0);

        assertEq(description, "Test Proposal");
        assertEq(yesVotes, 0);
        assertEq(endTime, block.timestamp + (VOTING_PERIOD * 1 days));
        assertEq(executed, false);
        assertEq(amount, proposalAmount);
        assertEq(proposalTarget, target);
    }

    function testVotingAndAutoExecution() public {
        // Setup
        vm.prank(alice);
        dao.deposit(4_000_000); // 4 NZDD

        vm.prank(bob);
        dao.deposit(1_000_000); // 1 NZDD

        address target = address(0x4);
        uint256 proposalAmount = 500_000; // 0.5 NZDD
        
        // Mint tokens to DAO for proposal execution
        nzdd.mint(address(dao), proposalAmount);

        vm.prank(alice);
        dao.createProposal("Test Proposal", proposalAmount, target);

        // Test voting - should auto-execute since Alice has enough voting power
        vm.prank(alice);
        dao.vote(0);

        (,,,bool executed,,) = dao.getProposal(0);
        assertTrue(executed);
        assertEq(nzdd.balanceOf(target), proposalAmount);
        assertEq(dao.totalDeposits(), 4_500_000); // 5 NZDD - 0.5 NZDD
    }

    function test_RevertIf_VoteTwice() public {
        vm.prank(alice);
        dao.deposit(1_000_000); // 1 NZDD

        address target = address(0x4);
        uint256 proposalAmount = 500_000; // 0.5 NZDD

        // Mint tokens to DAO for proposal execution
        nzdd.mint(address(dao), proposalAmount);

        vm.prank(alice);
        dao.createProposal("Test Proposal", proposalAmount, target);

        vm.prank(alice);
        dao.vote(0);

        vm.prank(alice);
        vm.expectRevert();
        dao.vote(0);
    }

    receive() external payable {}
}

// Add MockERC20 contract for testing
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public immutable decimals;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public totalSupply;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        require(balanceOf[from] >= amount, "Insufficient balance");
        
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}
