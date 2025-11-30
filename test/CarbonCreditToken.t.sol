// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {CarbonCreditToken} from "../src/CarbonCreditToken.sol";

error Not_Owner();
error Invalid_receiver_or_amount();
error Invalid_owner_or_amount();
error Insufficient_owner_balance();

contract CarbonCreditTokenTest is Test {
    CarbonCreditToken cct;
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        cct = new CarbonCreditToken(owner);
    }

    // modifiers for easy testing
    modifier creditsMinted() {
        vm.prank(owner);
        cct.mint(user1, 1000);
        _;
    }

    // Test cases for CarbonCreditToken functions
    function testOwnerIsSetCorrectly() public view {
        address tokenOwner = cct.OWNER();
        address expectedOwner = owner;
        assertEq(tokenOwner, expectedOwner);
    }

    function testTokenName() public view {
        string memory tokenName = cct.name();
        assertEq(keccak256(abi.encodePacked(tokenName)), keccak256(abi.encodePacked("Carbon Credit Token")));
    }

    function testTokenSymbol() public view {
        string memory tokenSymbol = cct.symbol();
        assertEq(keccak256(abi.encodePacked(tokenSymbol)), keccak256(abi.encodePacked("CCT")));
    }

    function testDecimals() public view {
        uint8 decimals = cct.decimals();
        assertEq(decimals, 18);
    }

    function testMintSuccessByOwner() public {
        vm.prank(owner);
        cct.mint(user1, 1000);
        assertEq(cct.balanceOf(user1), 1000 * 1e18);
    }

    function testMintWithCorrectDecimals() public {
        vm.prank(owner);
        cct.mint(user1, 1);
        assertEq(cct.balanceOf(user1), 1e18);
    }

    function testMintFailsWithNotOwner() public {
        vm.prank(user1);
        vm.expectRevert(Not_Owner.selector);
        cct.mint(user1, 1000);
    }

    function testMintFailsToInvalidAddress() public {
        vm.prank(owner);
        vm.expectRevert(Invalid_receiver_or_amount.selector);
        cct.mint(address(0), 1000);
    }

    function testMintFailsWithInvalidAmount() public {
        vm.prank(owner);
        vm.expectRevert(Invalid_receiver_or_amount.selector);
        cct.mint(user1, 0);
    }

    function testBurnSuccessByOwner() public creditsMinted {
        vm.prank(owner);
        cct.burn(user1, 500);
        assertEq(cct.balanceOf(user1), 500 * 1e18);
    }

    function testBurnFailsByNotOwner() public creditsMinted {
        vm.prank(user2);
        vm.expectRevert(Not_Owner.selector);
        cct.burn(user1, 1000);
    }

    function testBurnFailsToAddressZero() public creditsMinted {
        vm.prank(owner);
        vm.expectRevert(Invalid_owner_or_amount.selector);
        cct.burn(address(0), 1000);
    }

    function testBurnFailsWithZeroAmount() public creditsMinted {
        vm.prank(owner);
        vm.expectRevert(Invalid_owner_or_amount.selector);
        cct.burn(user1, 0);
    }

    function testApproveSuccessByOwner() public creditsMinted {
        vm.prank(owner);
        cct.approve(user1, user2, 500);
        assertEq(cct.allowance(user1, user2), 500 * 1e18);
    }

    function testApproveFailsByNotOwner() public creditsMinted {
        vm.prank(user1);
        vm.expectRevert(Not_Owner.selector);
        cct.approve(user1, user2, 500);
    }

    function testApproveFailsWithInvalidParameters() public creditsMinted {
        vm.prank(owner);
        vm.expectRevert(Invalid_owner_or_amount.selector);
        cct.approve(address(0), user2, 500);

        vm.prank(owner);
        vm.expectRevert(Invalid_owner_or_amount.selector);
        cct.approve(user1, address(0), 500);

        vm.prank(owner);
        vm.expectRevert(Invalid_owner_or_amount.selector);
        cct.approve(user1, user2, 0);
    }
}
