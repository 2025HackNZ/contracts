// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DAO.sol";

contract DAOTest is Test {
    DAO public dao;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    uint256 public constant MINIMUM_DEPOSIT = 1 ether;
    uint256 public constant VOTING_PERIOD = 7; // 7 days

    function setUp() public {
        dao = new DAO(MINIMUM_DEPOSIT, VOTING_PERIOD);
        // Fund test addresses
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
    }

    function testDeposit() public {
        vm.prank(alice);
        dao.deposit{value: 1 ether}();

        (uint256 depositAmount, uint256 joinedAt) = dao.getMemberInfo(alice);
        assertEq(depositAmount, 1 ether);
        assertEq(joinedAt, block.timestamp);
        assertEq(dao.totalDeposits(), 1 ether);
    }

    function test_RevertIf_DepositBelowMinimum() public {
        vm.prank(alice);
        vm.expectRevert();
        dao.deposit{value: 0.5 ether}();
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

    function testVoting() public {
        // Setup
        vm.prank(alice);
        dao.deposit{value: 4 ether}();

        vm.prank(bob);
        dao.deposit{value: 1 ether}();

        vm.prank(alice);
        dao.createProposal("Test Proposal", 0.5 ether, payable(address(0x4)));

        // Test voting
        vm.prank(alice);
        dao.vote(0);

        (,uint256 yesVotes,,,,) = dao.getProposal(0);
        // Alice deposited 4 ether, so voting power should be sqrt(4 ether) = 2 ether
        assertEq(yesVotes * 1e9, 2 ether);
    }

    function test_RevertIf_VoteTwice() public {
        vm.prank(alice);
        dao.deposit{value: 1 ether}();

        vm.prank(alice);
        dao.createProposal("Test Proposal", 0.5 ether, payable(address(0x4)));

        vm.prank(alice);
        dao.vote(0);

        vm.prank(alice);
        vm.expectRevert();
        dao.vote(0); // Should fail
    }

    function testExecuteProposal() public {
        address payable target = payable(address(0x4));
        uint256 proposalAmount = 0.5 ether;

        // Setup deposits
        vm.prank(alice);
        dao.deposit{value: 4 ether}();

        vm.prank(bob);
        dao.deposit{value: 1 ether}();

        // Create proposal
        vm.prank(alice);
        dao.createProposal("Test Proposal", proposalAmount, target);

        // Vote
        vm.prank(alice);
        dao.vote(0);

        // Fast forward past voting period
        vm.warp(block.timestamp + (VOTING_PERIOD * 1 days) + 1);

        // Execute proposal
        uint256 targetBalanceBefore = target.balance;
        dao.executeProposal(0);

        // Verify execution
        assertEq(target.balance - targetBalanceBefore, proposalAmount);
        assertEq(dao.totalDeposits(), 4.5 ether); // 5 ether - 0.5 ether

        (,,,bool executed,,) = dao.getProposal(0);
        assertTrue(executed);
    }

    function test_RevertIf_ExecuteProposalTwice() public {
        // Setup similar to testExecuteProposal
        address payable target = payable(address(0x4));

        vm.prank(alice);
        dao.deposit{value: 4 ether}();

        vm.prank(alice);
        dao.createProposal("Test Proposal", 0.5 ether, target);

        vm.prank(alice);
        dao.vote(0);

        vm.warp(block.timestamp + (VOTING_PERIOD * 1 days) + 1);

        dao.executeProposal(0);
        vm.expectRevert();
        dao.executeProposal(0); // Should fail
    }

    receive() external payable {}
}
