// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CarbonNFT is ERC721, Ownable {
    constructor(address owner) ERC721("Retired Credits", "RCCT") Ownable(owner) {}
}
