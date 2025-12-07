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
error InsufficientBalance();
error NoProceedsToWithdraw();

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
        token = marketplace.CARBON_CREDIT_TOKEN();
        vm.prank(owner);
        marketplace.addAuditor(auditor);
    }

    modifier tokenMinted() {
        vm.prank(projectOwner);
        marketplace.registerProject("Demo", projectOwner);
        vm.prank(auditor);
        marketplace.verifyProject(0, 100);
        _;
    }

    modifier projectListed() {
        vm.prank(projectOwner);
        marketplace.registerProject("Demo", projectOwner);
        vm.prank(auditor);
        marketplace.verifyProject(0, 50);

        // User lists credits for sale
        vm.prank(projectOwner);
        marketplace.listCreditsForSell(50, 1);
        _;
    }

    function testMarketplaceAdmin() public view {
        address _owner = marketplace.owner();
        assertEq(owner, _owner);
    }

    function testTokenOwnerIsMarketplace() public view {
        address tokenOwner = marketplace.CARBON_CREDIT_TOKEN().OWNER();
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
        (uint256 projectId, string memory name, address ownerAddr, bool verified, uint256 credits) =
            marketplace.projects(0);

        assertEq(projectId, 0);
        assertEq(name, "Project X");
        assertEq(ownerAddr, projectOwner);
        assertFalse(verified);
        assertEq(credits, 0);
    }

    function testVerifyProject() public {
        vm.prank(projectOwner);
        marketplace.registerProject("Project Y", projectOwner);

        vm.prank(auditor);
        marketplace.verifyProject(0, 100);

        (,,, bool verified, uint256 credits) = marketplace.projects(0);
        assertTrue(verified);
        assertEq(credits, 100e18);

        assertEq(token.balanceOf(projectOwner), 100e18);

        console.log(token.balanceOf(projectOwner));
        console.log(token.totalSupply());
    }

    function testDoubleVerificationFails() public {
        vm.prank(projectOwner);
        marketplace.registerProject("Project Y", projectOwner);

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
        vm.prank(user);
        marketplace.registerProject("Demo", user);
        vm.prank(auditor);
        marketplace.verifyProject(0, 50);

        // User lists credits for sale
        vm.prank(user);
        marketplace.listCreditsForSell(50, 1 * 1e18);

        (uint256 credits, address seller, uint256 pricePerCredit, bool isActive) = marketplace.listings(0);

        assertEq(credits, 50 * 1e18);
        assertEq(seller, address(user));
        assertEq(pricePerCredit, 1e18);
        assertTrue(isActive);

        assertEq(token.balanceOf(address(marketplace)), 50 * 1e18);
    }

    function testListingFailsWithInvalidAmount() public tokenMinted {
        vm.startPrank(user);
        vm.expectRevert(InvalidAmount.selector);
        marketplace.listCreditsForSell(0, 0);
    }

    function testListingFailsWithInvalidPrice() public tokenMinted {
        vm.startPrank(user);
        vm.expectRevert(InvalidPrice.selector);
        marketplace.listCreditsForSell(20, 0);
    }

    function testListingFailsWithInsufficientBalance() public tokenMinted {
        vm.startPrank(user);
        vm.expectRevert(InsufficientBalance.selector);
        marketplace.listCreditsForSell(2000, 10);
    }

    function testBuyCredit() public projectListed {
        vm.deal(buyer, 100 ether);
        vm.prank(buyer);
        marketplace.buyTokens{value: 50e18}(0);

        assertEq(token.balanceOf(buyer), 50e18);
        assertEq(marketplace.sellerProceeds(projectOwner), 50e18);
    }

    function testWitdrawProceeds() public projectListed {
        vm.deal(buyer, 100 ether);
        vm.prank(buyer);
        marketplace.buyTokens{value: 50e18}(0);

        vm.prank(projectOwner);
        marketplace.withdrawProceeds();
        assertEq(projectOwner.balance, 50e18);
    }

    function testWitdrawProceedsFailsWithInsufficientProceeds() public projectListed {
        vm.prank(projectOwner);
        vm.expectRevert(NoProceedsToWithdraw.selector);
        marketplace.withdrawProceeds();
    }

    function testWithdrawCharges() public {
        vm.deal(address(marketplace), 100);

        vm.prank(owner);
        marketplace.withdrawCharges();
        assertEq(owner.balance, 100);
    }

    function testRetireCredit() public projectListed {
        vm.deal(buyer, 100 ether);
        vm.prank(buyer);
        marketplace.buyTokens{value: 50e18}(0);

        vm.prank(buyer);
        marketplace.retireCredit(50);

        assertEq(token.balanceOf(buyer), 0);
    }

    function testRetireFailsWithInvalidBalance() public {
        vm.prank(user);
        vm.expectRevert(InsufficientBalance.selector);
        marketplace.retireCredit(200);
    }

    // TODO: Check later for accuracy
    function testGetAllListingReturnsAllListings() public projectListed {
        // Create second project and listing
        vm.prank(user);
        marketplace.registerProject("Second Project", user);
        vm.prank(auditor);
        marketplace.verifyProject(1, 30);

        // List second batch of credits
        vm.prank(user);
        marketplace.listCreditsForSell(30, 2);

        // Get all listings
        CarbonMarketplace.Listing[] memory allListings = marketplace.getAllListings();

        // Assert array length
        assertEq(allListings.length, 2);

        // Verify first listing details
        assertEq(allListings[0].credits, 50e18);
        assertEq(allListings[0].seller, projectOwner);
        assertEq(allListings[0].pricePerCredit, 1);
        assertTrue(allListings[0].isActive);

        // Verify second listing details
        assertEq(allListings[1].credits, 30e18);
        assertEq(allListings[1].seller, user);
        assertEq(allListings[1].pricePerCredit, 2);
        assertTrue(allListings[1].isActive);
    }

    function testGetAllProjects() public {
        // Create first project
        vm.prank(projectOwner);
        marketplace.registerProject("Project 1", projectOwner);

        // Create second project
        vm.prank(user);
        marketplace.registerProject("Project 2", user);

        CarbonMarketplace.Project[] memory projects = marketplace.getAllProjects();

        assertEq(projects.length, 2);
        assertEq(projects[0].name, "Project 1");
        assertEq(projects[0].owner, projectOwner);
        assertEq(projects[1].name, "Project 2");
        assertEq(projects[1].owner, user);
    }

    function testGetSellerProceedsNonZero() public projectListed {
        // Buy tokens to generate proceeds
        vm.deal(buyer, 100 ether);
        vm.prank(buyer);
        marketplace.buyTokens{value: 50e18}(0);

        // Check seller proceeds
        vm.prank(projectOwner);
        assertEq(marketplace.getSellerProceeds(), 50e18);
    }

    function testGetNextProjectIdStartsAtZero() public view {
        assertEq(marketplace.getNextProjectId(), 0);
    }

    function testGetNextProjectIdIncrements() public {
        vm.prank(projectOwner);
        marketplace.registerProject("Test Project", projectOwner);
        assertEq(marketplace.getNextProjectId(), 1);

        vm.prank(projectOwner);
        marketplace.registerProject("Test Project 2", projectOwner);
        assertEq(marketplace.getNextProjectId(), 2);
    }

    function testGetNextListingIdStartsAtZero() public view {
        assertEq(marketplace.getNextListingId(), 0);
    }

    function testGetNextListingIdIncrements() public tokenMinted {
        vm.startPrank(projectOwner);
        marketplace.listCreditsForSell(50, 1);
        assertEq(marketplace.getNextListingId(), 1);

        marketplace.listCreditsForSell(50, 2);
        assertEq(marketplace.getNextListingId(), 2);
        vm.stopPrank();
    }

    function testGetAllProjectsEmpty() public view {
        CarbonMarketplace.Project[] memory projects = marketplace.getAllProjects();
        assertEq(projects.length, 0);
    }
}
