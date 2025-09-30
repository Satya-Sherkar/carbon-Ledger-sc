// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CarbonCreditToken is ERC20 {
    // Errors
    error InvalidAddress();
    error InsufficientBalance();
    error UnauthorizedAccount();

    // Immutable
    address public immutable OWNER;

    // Constructor
    constructor(address _owner) ERC20("Carbon Credit Token", "CCT") {
        OWNER = _owner;
    }

    // Modifier
    modifier onlyOwner() {
        if (msg.sender != OWNER) {
            revert UnauthorizedAccount();
        }
        _;
    }

    // Functions
    function mint(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) {
            revert InvalidAddress();
        }
        _mint(to, amount);
    }

    function burn(address holder, uint256 amount) external onlyOwner {
        if (amount < balanceOf(holder)) {
            revert InsufficientBalance();
        }
        _burn(holder, amount);
    }

    function approve_(address holder, address spender, uint256 value) external onlyOwner {
        _approve(holder, spender, value);
    }
}
