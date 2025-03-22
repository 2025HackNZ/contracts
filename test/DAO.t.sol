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

    uint256 public constant MINIMUM_DEPOSIT = 1 ether;
    uint256 public constant VOTING_PERIOD = 7; // 7 days

    function setUp() public {
        // Deploy mock NZDD token
        nzdd = new MockERC20("New Zealand Digital Dollar", "NZDD");
        dao = new DAO(address(nzdd), MINIMUM_DEPOSIT, VOTING_PERIOD);
        
        // Mint and approve tokens for test addresses
        nzdd.mint(alice, 10 ether);
        nzdd.mint(bob, 10 ether);
        nzdd.mint(charlie, 10 ether);
        
        vm.prank(alice);
        nzdd.approve(address(dao), type(uint256).max);
        vm.prank(bob);
        nzdd.approve(address(dao), type(uint256).max);
        vm.prank(charlie);
        nzdd.approve(address(dao), type(uint256).max);
    }

    function testDeposit() public {
        vm.prank(alice);
        dao.deposit(1 ether);

        (uint256 depositAmount, uint256 joinedAt) = dao.getMemberInfo(alice);
        assertEq(depositAmount, 1 ether);
        assertEq(joinedAt, block.timestamp);
        assertEq(dao.totalDeposits(), 1 ether);
    }

    function test_RevertIf_DepositBelowMinimum() public {
        vm.prank(alice);
        vm.expectRevert();
        dao.deposit(0.5 ether);
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
        dao.deposit(4 ether);

        vm.prank(bob);
        dao.deposit(1 ether);

        address target = address(0x4);
        uint256 proposalAmount = 0.5 ether;
        
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
        assertEq(dao.totalDeposits(), 4.5 ether); // 5 ether - 0.5 ether
    }

    function test_RevertIf_VoteTwice() public {
        vm.prank(alice);
        dao.deposit(1 ether);

        vm.prank(alice);
        dao.createProposal("Test Proposal", 0.5 ether, address(0x4));

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
    uint8 public decimals = 18;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public totalSupply;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
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
