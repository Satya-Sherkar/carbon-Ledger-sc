// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error Not_Owner();
error Invalid_receiver_or_amount();
error Invalid_owner_or_amount();
error Insufficient_owner_balance();

/**
 * @title Carbon Credit Token.
 * @author Satyam Sherkar GitHub: https://github.com/Satya-Sherkar
 * @notice This is a test contract. Under Development. 
 */
contract CarbonCreditToken is ERC20 {
    // owner will be marketplace contract
    address public immutable OWNER;

    // constructor
    constructor(address owner) ERC20("Carbon Credit Token", "CCT") {
        OWNER = owner;
    }

    // modifiers
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != OWNER) {
            revert Not_Owner();
        }
    }

    // main functions
    function mint(address receiver, uint256 amount) external onlyOwner {
        if (receiver == address(0) || amount <= 0) {
            revert Invalid_receiver_or_amount();
        }
        _mint(receiver, amount * 1e18);
    }

    function burn(address owner, uint256 amount) external onlyOwner {
        if (owner == address(0) || amount <= 0) {
            revert Invalid_owner_or_amount();
        }
        if (amount > balanceOf(owner)) {
            revert Insufficient_owner_balance();
        }
        _burn(owner, amount * 1e18);
    }

    function approve(address owner, address spender, uint256 amount) external onlyOwner {
        if (owner == address(0) || spender == address(0) || amount <= 0) {
            revert Invalid_owner_or_amount();
        }
        _approve(owner, spender, amount * 1e18);
    }
}