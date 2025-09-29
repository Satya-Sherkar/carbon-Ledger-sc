// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import{DeployCarbonMarketplace} from "../script/DeployCarbonMarketplace.s.sol";
import{CarbonMarketplace} from "../src/CarbonMarketplace.sol";

contract DeployScriptTest is Test {
    DeployCarbonMarketplace deployer;
    CarbonMarketplace marketplace;

    function setUp() public {
        deployer = new DeployCarbonMarketplace();
        marketplace = deployer.run();
    }

    function testAdminAddress() public view{
        address admin = marketplace.owner();
        assertEq(admin, 0xA2032c43F562B7dd7e7A7A3F36f121Ad7D5265E2);
    }

    function testScriptDeploysMarketplaceAndToken() public view {
        address _marketplace = address(marketplace);
        address _creditToken = address(marketplace.carbonCreditToken());
        
        assertEq(_marketplace, address(marketplace));
        assertEq(_creditToken, address(marketplace.carbonCreditToken()));
    }
}