// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {CarbonCreditToken} from "./CarbonCreditToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Carbon Credit Marketplace Test Contract
 * @author Satyam Sherkar
 * @notice This is Test contract.
 */
contract CarbonMarketplace is Ownable {
    /*//////////////////////////////////////////////////// 
                            Errors
    ///////////////////////////////////////////////////*/
    error NotAuditor();
    error ProjectAlreadyVerified();
    error InvalidAddress();
    error InsufficientBalance();
    error InvalidAmount();
    error InvalidPrice();
    error CreditSellingInactive();
    error InsufficientPayment();
    error NoProceedsToWithdraw();
    error WithdrawFailed();
    error TransferFailed();
    error InvalidOwener();

    /*//////////////////////////////////////////////////// 
                            Immutable
    ///////////////////////////////////////////////////*/
    CarbonCreditToken public immutable CARBON_CREDIT_TOKEN;

    /*//////////////////////////////////////////////////// 
                            Constructor
    ///////////////////////////////////////////////////*/

    /**
     *
     * @param admin is set as owner of this marketplace contract..
     * @notice Owner of CarbonCreditToken is initialized as this contract(Marketplace).
     */
    constructor(address admin) Ownable(admin) {
        CARBON_CREDIT_TOKEN = new CarbonCreditToken(address(this));
    }

    /*//////////////////////////////////////////////////// 
                         Type Declarations
    ///////////////////////////////////////////////////*/
    struct Project {
        uint256 projectId;
        string name;
        address owner;
        bool isVerified;
        uint256 credits;
    }

    struct Listing {
        uint256 credits;
        address seller;
        uint256 pricePerCredit;
        bool isActive;
    }

    /*//////////////////////////////////////////////////// 
                    Mappings and variables
    ///////////////////////////////////////////////////*/

    /**
     * @notice This mapping maps Project Id to Project
     */
    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId;

    /**
     * @notice This mapping maps auditor address to boolean.
     */
    mapping(address => bool) public auditors;

    /**
     * @notice This mapping maps Listing to Listing Id.
     */
    mapping(uint256 => Listing) public listings;
    uint256 public nextListingId;

    /**
     * @notice This mapping maps seller address to his proceeds(amount he can withdraw).
     */
    mapping(address => uint256) public sellerProceeds;

    /*//////////////////////////////////////////////////// 
                            Events
    ///////////////////////////////////////////////////*/
    event AuditorAdded(address indexed auditor);
    event AuditorRemoved(address indexed auditor);
    event ProjectRegistered(uint256 indexed projectId, address indexed owner);
    event ProjectVerified(uint256 indexed id, uint256 indexed credits, address indexed auditor);
    event CreditsListed(
        uint256 indexed listingId, address indexed seller, uint256 amount, uint256 indexed pricePerCredit
    );
    event CreditsPurchased(
        uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 creditAmount, uint256 price
    );
    event ProceedsWithdrawn(address indexed seller, uint256 indexed amount);
    event CreditsRetired(address indexed creditHolder, uint256 indexed retiredCreditAmount);

    /*//////////////////////////////////////////////////// 
                            Modifiers
    ///////////////////////////////////////////////////*/
    modifier onlyAuditor() {
        if (!auditors[msg.sender]) {
            revert NotAuditor();
        }
        _;
    }

    /*//////////////////////////////////////////////////// 
                     Functions
    ///////////////////////////////////////////////////*/
    function addAuditor(address auditor) external onlyOwner {
        auditors[auditor] = true;
        emit AuditorAdded(auditor);
    }

    function removeAuditor(address auditor) external onlyOwner {
        auditors[auditor] = false;
        emit AuditorRemoved(auditor);
    }

    function isAuditor(address _auditor) external view returns (bool) {
        return auditors[_auditor];
    }

    function registerProject(string calldata projectName, address projectOwner) external {
        if (projectOwner == address(0)) {
            revert InvalidAddress();
        }
        projects[nextProjectId] =
            Project({projectId: nextProjectId, name: projectName, owner: projectOwner, isVerified: false, credits: 0});
        emit ProjectRegistered(nextProjectId, projectOwner);
        nextProjectId++;
    }

    function verifyProject(uint256 projectId, uint256 credits) external onlyAuditor {
        Project storage project = projects[projectId];
        if (project.isVerified) revert ProjectAlreadyVerified();

        project.isVerified = true;
        project.credits = credits;

        CARBON_CREDIT_TOKEN.mint(project.owner, credits);
        emit ProjectVerified(projectId, credits, msg.sender);
    }

    // Functions for List/sell and buy credits
    function listCreditsForSell(uint256 creditAmount, uint256 pricePerCredit) external {
        if (creditAmount == 0) {
            revert InvalidAmount();
        }
        if (pricePerCredit == 0) {
            revert InvalidPrice();
        }
        if (CARBON_CREDIT_TOKEN.balanceOf(msg.sender) < creditAmount) {
            revert InsufficientBalance();
        }

        CARBON_CREDIT_TOKEN.approve_(msg.sender, address(this), creditAmount);
        bool success = CARBON_CREDIT_TOKEN.transferFrom(msg.sender, address(this), creditAmount);
        if (!success) {
            revert TransferFailed();
        }

        listings[nextListingId] =
            Listing({credits: creditAmount, seller: msg.sender, pricePerCredit: pricePerCredit * 1e18, isActive: true});

        emit CreditsListed(nextListingId, msg.sender, creditAmount, pricePerCredit);
        nextListingId++;
    }

    function haltSelling(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        if (msg.sender != listing.seller) {
            revert InvalidOwener();
        }
        listing.isActive = false;
    }

    function resumeSelling(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        if (msg.sender != listing.seller) {
            revert InvalidOwener();
        }
        listing.isActive = true;
    }

    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        if (msg.sender != listing.seller) {
            revert InvalidOwener();
        }
        
        bool success = CARBON_CREDIT_TOKEN.transfer(msg.sender, listing.credits);
        if (!success) {
            revert TransferFailed();
        }

        listing.isActive = false;
        listing.credits = 0;
        listing.pricePerCredit = 0;
    }

    function buyTokens(uint256 listingId) external payable {
        Listing storage listing = listings[listingId];
        if (!listing.isActive) {
            revert CreditSellingInactive();
        }

        uint256 totalPrice = listing.credits * listing.pricePerCredit;
        if (msg.value < totalPrice) {
            revert InsufficientPayment();
        }

        // Token transfer to buyer
        bool success = CARBON_CREDIT_TOKEN.transfer(msg.sender, listing.credits);
        if (!success) {
            revert TransferFailed();
        }
        sellerProceeds[listing.seller] += msg.value;

        listing.isActive = false;

        // Refund excess payment
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit CreditsPurchased(listingId, msg.sender, listing.seller, listing.credits, totalPrice);
    }

    function withdrawProceeds() external {
        uint256 proceeds = sellerProceeds[msg.sender];
        if (proceeds == 0) revert NoProceedsToWithdraw();

        (bool success,) = payable(msg.sender).call{value: proceeds}("");
        if (!success) revert WithdrawFailed();

        sellerProceeds[msg.sender] = 0;
        emit ProceedsWithdrawn(msg.sender, proceeds);
    }

    function retireCredit(uint256 amount) external {
        if (CARBON_CREDIT_TOKEN.balanceOf(msg.sender) < amount) {
            revert InsufficientBalance();
        }

        CARBON_CREDIT_TOKEN.burn(msg.sender, amount);
        emit CreditsRetired(msg.sender, amount);
    }

    function withdrawCharges() external onlyOwner {
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        if (!callSuccess) revert WithdrawFailed();
    }
}
