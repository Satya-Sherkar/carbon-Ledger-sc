// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 *  @title CarbonCreditToken Test
 *  @author Satyam Sherkar
 *  @notice This contract implements an ERC20 token for carbon credits
 *  @dev Also see OpenZeppelin's ERC20 for inherited properties.
 */
contract CarbonCreditToken is ERC20 {
    error InvalidAddress();
    error InsufficientBalance();
    error UnauthorizedAccount();

    /**
     *  @notice Address of the contract owner(marketplace contract)
     */
    address public immutable OWNER;

    /**
     * @notice Initializes the contract with an owner address
     * @dev Sets up the ERC20 token with name "Carbon Credit Token" and symbol "CCT"
     * @param owner Address (Marketplace Contract) that will have permission to mint and burn tokens and all other functions of this contract.
     */
    constructor(address owner) ERC20("Carbon Credit Token", "CCT") {
        OWNER = owner;
    }

    /**
     * @notice Restricts function access to contract owner
     */
    modifier onlyOwner() {
        if (msg.sender != OWNER) {
            revert UnauthorizedAccount();
        }
        _;
    }

    /**
     * @notice Mints new tokens to a specified address
     */
    function mint(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) {
            revert InvalidAddress();
        }
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from a holder's address, use for retiring credits
     * @param holder Address from which to burn tokens(Retire)
     * @param amount Number of tokens to burn(Retire)
     */
    function burn(address holder, uint256 amount) external onlyOwner {
        if (amount > balanceOf(holder)) {
            revert InsufficientBalance();
        }
        _burn(holder, amount);
    }

    /**
     * @notice Approves spending of tokens on behalf of a holder, use for sending tokens for listing in marketplace contract.
     */
    function approve_(address holder, address spender, uint256 value) external onlyOwner {
        _approve(holder, spender, value);
    }
}
