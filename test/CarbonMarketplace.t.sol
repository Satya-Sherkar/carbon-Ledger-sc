// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {CarbonMarketplace} from "../src/CarbonMarketplace.sol";
import {CarbonCreditToken} from "../src/CarbonCreditToken.sol";

error InvalidAddress();
error ProjectAlreadyVerified();
error InvalidAmount();
error InvalidPrice();
error CreditSellingInactive();

contract CarbonMarketplaceTest is Test {
    CarbonMarketplace marketplace;
    CarbonCreditToken token;

    address owner = makeAddr("owner");
    address auditor = makeAddr("auditor");
    address projectOwner = makeAddr("projectOwner");
    address buyer = makeAddr("buyer");
    address user = makeAddr("user");

    function setUp() public {
        marketplace = new CarbonMarketplace(owner);
        token = marketplace.carbonCreditToken();
        vm.prank(owner);
        marketplace.addAuditor(auditor);
    }

    modifier tokenMinted() {
        vm.prank(user);
        marketplace.registerProject("Demo", user);
        vm.prank(auditor);
        marketplace.verifyProject(0, 100);
        _;
    }

    modifier projectListed() {
        vm.prank(user);
        marketplace.registerProject("Demo", user);
        vm.prank(auditor);
        marketplace.verifyProject(0, 50);

        // User lists credits for sale
        vm.startPrank(user);
        marketplace.listCreditsForSell(50, 1);
        vm.stopPrank();
        _;
    }

    function testMarketplaceAdmin() public view {
        address _owner = marketplace.owner();
        assertEq(owner, _owner);
    }

    function testTokenOwnerIsMarketplace() public view {
        address tokenOwner = marketplace.carbonCreditToken().owner();
        assertEq(address(marketplace), tokenOwner);
    }

    function testAddAndRemoveAuditor() public {
        vm.prank(owner);
        marketplace.addAuditor(auditor);
        assertTrue(marketplace.isAuditor(auditor));

        vm.prank(owner);
        marketplace.removeAuditor(auditor);
        assertFalse(marketplace.isAuditor(auditor));
    }

    function testZeroAddressCannotRegister() public {
        vm.prank(projectOwner);
        vm.expectRevert(InvalidAddress.selector);
        marketplace.registerProject("Projet A", address(0));
    }

    function testRegisterProject() public {
        vm.prank(projectOwner);
        marketplace.registerProject("Project X", projectOwner);
        (
            uint256 projectId,
            string memory name,
            address ownerAddr,
            bool verified,
            uint256 credits
        ) = marketplace.projects(0);
        assertEq(projectId, 0);
        assertEq(name, "Project X");
        assertEq(ownerAddr, projectOwner);
        assertFalse(verified);
        assertEq(credits, 0);
    }

    function testVerifyProject() public {
        vm.prank(projectOwner);
        marketplace.registerProject("Project Y", projectOwner);

        vm.prank(owner);
        marketplace.addAuditor(auditor);

        vm.prank(auditor);
        marketplace.verifyProject(0, 100);

        (, , , bool verified, uint256 credits) = marketplace.projects(0);
        assertTrue(verified);
        assertEq(credits, 100);

        assertEq(token.balanceOf(projectOwner), 100);

        console.log(token.balanceOf(projectOwner));
        console.log(token.totalSupply());
    }

    function testDoubleVerificationFails() public {
        vm.prank(projectOwner);
        marketplace.registerProject("Project Y", projectOwner);

        vm.prank(owner);
        marketplace.addAuditor(auditor);

        vm.startPrank(auditor);
        marketplace.verifyProject(0, 100);

        vm.expectRevert(ProjectAlreadyVerified.selector);
        marketplace.verifyProject(0, 200);
    }

    function testNonAuditorCannotVerify() public {
        vm.prank(user);
        marketplace.registerProject("Demo", user);

        vm.prank(user);
        vm.expectRevert();
        marketplace.verifyProject(0, 100);
    }

    function testListCreditsForSell() public {
        // Register and verify project, so user receives tokens
        vm.prank(user);
        marketplace.registerProject("Demo", user);
        vm.prank(auditor);
        marketplace.verifyProject(0, 50);

        // User lists credits for sale
        vm.startPrank(user);
        marketplace.listCreditsForSell(50, 1);
        vm.stopPrank();

        (
            uint256 credits,
            address seller,
            uint256 pricePerCredit,
            bool isActive
        ) = marketplace.Listings(0);
        assertEq(credits, 50);
        assertEq(seller, address(user));
        assertEq(pricePerCredit, 1e18);
        assertTrue(isActive);

        assertEq(token.balanceOf(address(marketplace)), 50);
    }

    function testListingFailsWithInvalidAmount() public tokenMinted {
        vm.startPrank(user);
        vm.expectRevert(InvalidAmount.selector);
        marketplace.listCreditsForSell(0, 0);
    }

    function testBuyCredit() public projectListed {
        vm.deal(buyer, 100 ether);
        vm.prank(buyer);
        marketplace.buyTokens{value: 50e18}(0);
        assertEq(token.balanceOf(buyer), 50);
        assertEq(marketplace.sellerProceeds(user), 50e18);
    }


    function testWitdrawProceeds() public projectListed {
        vm.deal(buyer, 100 ether);
        vm.prank(buyer);
        marketplace.buyTokens{value: 50e18}(0);

        vm.prank(user);
        marketplace.withdrawProceeds();
        assertEq(user.balance, 50e18);
    }

    function testWithdrawCharges() public {
        vm.deal(address(marketplace), 100);

        vm.prank(owner);
        marketplace.withdrawCharges();
        assertEq(owner.balance, 100);
    }
}
