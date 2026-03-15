// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SimpleAuction.sol";

contract SimpleAuctionTest is Test {
    SimpleAuction public simpleauction;

    // test directions
    address john = makeAddr("john");
    address jane = makeAddr("jane");
    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    function setUp() public {
        simpleauction = new SimpleAuction(1 days, payable(jane)); // contract deploy
    }

    function testBid() public {
        vm.prank(alice);
        vm.deal(alice, 10 ether);
        uint256 saldoAlice = alice.balance;
        console.log("Saldo de Alice antes de pujar:", saldoAlice);
        simpleauction.bid{value: 1 ether}();
        console.log("Saldo de Alice despues de pujar:", alice.balance);
        vm.deal(john, 5 ether);
        assertEq(simpleauction.highestBidder(), alice);
        assertEq(simpleauction.highestBid(), 1 ether);
        console.log("Saldo de John antes de pujar:", john.balance);
        vm.prank(john);
        simpleauction.bid{value: 4 ether}();
        assertEq(simpleauction.highestBidder(), john);
        assertEq(simpleauction.highestBid(), 4 ether);
        console.log("Saldo de John despues de pujar:", john.balance);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(SimpleAuction.AuctionAlreadyEnded.selector);
        vm.prank(john);
        simpleauction.bid{value: 1 ether}();
    }

    function testBidNotHighEnough() public {
        vm.prank(alice);
        vm.deal(alice, 10 ether);
        simpleauction.bid{value: 2 ether}();
        vm.prank(bob);
        vm.deal(bob, 10 ether);
        vm.expectRevert(abi.encodeWithSelector(SimpleAuction.BidNotHighEnough.selector, 2 ether));
        simpleauction.bid{value: 1 ether}();
    }

    function testWithdraw() public {
        vm.prank(alice);
        vm.deal(alice, 10 ether);
        simpleauction.bid{value: 1 ether}();
        vm.deal(john, 10 ether);
        vm.prank(john);
        simpleauction.bid{value: 4 ether}();
        vm.prank(alice);
        bool success = simpleauction.withdraw();
        assertEq(success, true);
        assertEq(alice.balance, 10 ether);
        assertEq(simpleauction.beneficiary(), jane);
        assertEq(simpleauction.highestBid(), 4 ether);
    }

    function testWithdrawNotHighEnough() public {
        vm.prank(alice);
        vm.deal(alice, 10 ether);
        simpleauction.bid{value: 1 ether}();
        vm.prank(john);
        vm.deal(john, 10 ether);
        simpleauction.bid{value: 4 ether}();
        vm.prank(bob);
        assertEq(simpleauction.withdraw(), true);
    }

    function testAuctionEnd() public {
        vm.prank(alice);
        vm.deal(alice, 10 ether);
        simpleauction.bid{value: 1 ether}();
        vm.prank(john);
        vm.deal(john, 10 ether);
        simpleauction.bid{value: 4 ether}();
        vm.prank(bob);
        vm.warp(block.timestamp + 2 days);
        simpleauction.auctionEnd();
        assertEq(simpleauction.beneficiary(), jane);
        assertEq(simpleauction.highestBid(), 4 ether);
        assertEq(jane.balance, 4 ether);
    }
}
