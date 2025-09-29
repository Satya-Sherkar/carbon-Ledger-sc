// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {CarbonCreditToken} from "../src/CarbonCreditToken.sol";

contract CarbonCreditTokenTest is Test {
    CarbonCreditToken token;
    // Admin will be address of marketplace contract
    address admin = makeAddr("admin");
    address user = makeAddr("user");
    address projectOwner = makeAddr("projectOwner");

    function setUp() public {
        token = new CarbonCreditToken(admin);
    }

    function testTokenNameAndSymbol() public view {
        string memory name = token.name();
        string memory symbol = token.symbol();
        assertEq(keccak256(abi.encodePacked(name)), keccak256(abi.encodePacked("Carbon Credit Token")));
        assertEq(keccak256(abi.encodePacked(symbol)), keccak256(abi.encodePacked("CCT")));
    }

    function testInitialSupplyToBeZero() public view {
        uint256 initialSupply = token.totalSupply();
        // expectedInitialSupply = 0;
        assertEq(initialSupply, 0);
    }

    function testMintFailsByNonOwner() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 100);
    }

    function testMintByAdmin() public {
        vm.prank(admin);
        token.mint(projectOwner, 100);

        assertEq(token.balanceOf(projectOwner), 100);
    }

    modifier tokenMinted() {
        vm.prank(admin);
        token.mint(projectOwner, 100);
        _;
    }

    function testBurnByAdmin() public tokenMinted {
        vm.prank(admin);
        token.burn(projectOwner, 100);

        assertEq(token.balanceOf(projectOwner), 0);
    }

    function testMintFailsToAddressZero() public {
        vm.prank(admin);
        vm.expectRevert();
        token.mint(address(0), 100);
    }

    function testBurnFailsWithLessBalance() public {
        vm.prank(admin);
        vm.expectRevert();
        token.burn(projectOwner, 100);
    }
}
