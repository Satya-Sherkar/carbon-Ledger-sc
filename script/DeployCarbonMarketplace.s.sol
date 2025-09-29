// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {CarbonMarketplace} from "../src/CarbonMarketplace.sol";

contract DeployCarbonMarketplace is Script {
    address ADMIN = 0xA2032c43F562B7dd7e7A7A3F36f121Ad7D5265E2;

    function run() external returns (CarbonMarketplace) {
        vm.startBroadcast();
        CarbonMarketplace marketplace = new CarbonMarketplace(ADMIN);
        vm.stopBroadcast();
        return marketplace;
    }
}
