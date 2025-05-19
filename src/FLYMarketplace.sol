// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "forge-std/console.sol";

contract FLYMarketplace is ReentrancyGuard, Ownable, Pausable {

    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Listing)) public listing; 

    uint256 public listFee;
    uint256 public buyFee;
    uint256 public collectedFees;

    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event NFTSold(address indexed buyer, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 price);
    event NFTFeeCollected(address indexed user, uint256 indexed fee);
    event WithdrawnFees(address indexed owner, uint256 indexed feesToWithdraw);

    constructor(uint256 listFee_, uint256 buyFee_) Ownable(msg.sender) {
        listFee = listFee_;
        buyFee = buyFee_;
    }

    /**
     * @notice Lists an NFT on the marketplace with a given price and collects the fee
     * @dev Requires the caller to be the owner of the NFT and to pay the fee
     * @param nftAddress_ Address of the ERC721 contract
     * @param tokenId_ Token ID of the NFT to list
     * @param price_ Token price
     * Emits the NFTListed event and the NFTFeeCollected
     */
    function listNFT(address nftAddress_, uint256 tokenId_, uint256 price_) external payable whenNotPaused nonReentrant {
        require(price_ > 0, "Price can not be 0");
        address owner_ = IERC721(nftAddress_).ownerOf(tokenId_);
        require(owner_ == msg.sender, "You are not the owner of the NFT");

        uint256 nftListFee_ = (price_ * listFee) / 100;
        require(msg.value == nftListFee_, "Incorrect list fee");
        collectedFees += nftListFee_;

        Listing memory listing_ = Listing({
            seller: msg.sender, 
            nftAddress: nftAddress_, 
            tokenId: tokenId_, 
            price: price_
        });
        listing[nftAddress_][tokenId_] = listing_;

        emit NFTListed(msg.sender, nftAddress_, tokenId_, price_);
        emit NFTFeeCollected(msg.sender, nftListFee_);
    }

    /**
     * @notice Purchases a listed NFT by paying the exact listing price
     * @dev Requires the NFT to be listed and `msg.value` to match the price
     * @param nftAddress_ Address of the ERC721 contract
     * @param tokenId_ Token ID of the NFT to list
     * Emits the NFTSold event
     */
    function buyNFT(address nftAddress_, uint256 tokenId_) external payable whenNotPaused nonReentrant {
        Listing memory listing_ = listing[nftAddress_][tokenId_];
        require(listing_.price > 0, "Listing not exists");  
        uint256 nftBuyFee_ = (listing_.price * buyFee) / 100;
        require(msg.value == listing_.price + nftBuyFee_, "Incorrect price");

        // require(msg.value == nftBuyFee_, "Incorrect buy fee");
        collectedFees += nftBuyFee_;

        delete listing[nftAddress_][tokenId_];

        IERC721(nftAddress_).safeTransferFrom(listing_.seller, msg.sender, listing_.tokenId);

        (bool success, ) = listing_.seller.call{value: listing_.price + nftBuyFee_}("");
        require(success, "Transfer failed");

        emit NFTSold(msg.sender, listing_.seller, listing_.nftAddress, listing_.tokenId, listing_.price);
        emit NFTFeeCollected(msg.sender, nftBuyFee_);
    }

    /**
     * @notice Cancels an active NFT listing
     * @dev Only the seller who created the listing can cancel it
     * @param nftAddress_ Address of the ERC721 contract
     * @param tokenId_ Token ID of the NFT to delist
     * Emits a NFTCanceled event
     */
    function cancelList(address nftAddress_, uint256 tokenId_) external  whenNotPaused nonReentrant {
        Listing memory listing_ = listing[nftAddress_][tokenId_];
        require(listing_.seller == msg.sender, "You are not the listing owner");

        console.log("Listing seller:", listing_.seller);
        console.log("msg.sender:", msg.sender);

        delete listing[nftAddress_][tokenId_];

        emit NFTCanceled(msg.sender, nftAddress_, tokenId_);
    }

    /**
     * @notice Allows owner to withdraw the collected fees
     */
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 feesToWithdraw = collectedFees;
        require(feesToWithdraw > 0, "No fees to withdraw");

        collectedFees = 0;

        (bool success, ) = msg.sender.call{value: feesToWithdraw}("");
        require(success, "Transfer failed");

        emit WithdrawnFees(msg.sender, feesToWithdraw);
    }

    /**
     * @notice Allows the owner to modify the list fee
     */
    function setListFee(uint256 newListFee_) external onlyOwner {
        require(newListFee_ <= 100, "List fee to high");
        listFee = newListFee_;
    }

    /**
     * @notice Allows the owner to modify the buy fee
     */
    function setBuyFee(uint256 newBuyFee_) external onlyOwner {
        require(newBuyFee_ <= 100, "Buy fee to high");
        buyFee = newBuyFee_;
    }

    /**
     * @notice Pauses the marketplace (emergency stop)
     */
    function pause() external onlyOwner() {
        _pause();
    }

    /**
     * @notice Unpauses the marketplace
     */
    function unpause() external onlyOwner() {
        _unpause();
    }

}