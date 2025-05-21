// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/forge-std/src/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../src/FLYMarketplace.sol";

contract MockNFT is ERC721 {

    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to_, uint256 tokenId_) external {
        _mint(to_, tokenId_);
    }

}  

contract NFTMarketplaceTest is Test {

    FLYMarketplace marketplace;
    MockNFT nft;
    address deployer = vm.addr(1);
    address user = vm.addr(2);
    uint256 tokenId = 0;
    uint256 listFee = 1;
    uint256 buyFee = 3;

    function setUp() public {
        vm.startPrank(deployer);
        marketplace =  new FLYMarketplace(listFee, buyFee);
        nft = new MockNFT();
        vm.stopPrank();

        vm.startPrank(user);
        nft.mint(user, 0);
        vm.stopPrank();
    }

    /**
     * @notice Checks that the NFT was correctly minted
     */
    function test_MintNFT() public view {
        address ownerOf = nft.ownerOf(tokenId);
        assert(ownerOf == user);
    }


    /** LIST NFT */

    /**
     * @notice Allows the owner to list their NFT successfully.
     * @dev Verifies that listing is stored in the mapping after listing.
     */
    function test_ListNFTCorrectly() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);

        uint256 price_ = 1 ether;
        uint256 nftListFee_ = (price_ * listFee) / 100;

        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: nftListFee_}(address(nft), tokenId, price_);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assertEq(sellerBefore, address(0));
        assertEq(sellerAfter, user);
        assertEq(marketplace.collectedFees(), nftListFee_);

        vm.stopPrank();
    }

    /**
     * @notice Reverts if the sended fee is not correct
     */
    function test_RevertsIfIncorrectFee() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);

        uint256 price_ = 1 ether;
        uint256 nftListFee_ = (price_ * listFee) / 100;

        vm.expectRevert("Incorrect list fee");
        marketplace.listNFT{value: nftListFee_ - 1}(address(nft), tokenId, price_);

        vm.stopPrank();
    }

    /**
     * @notice Reverts if listing an NFT with price = 0.
     */
    function test_RevertsIfPriceIsZero() public {
        vm.startPrank(user);

        vm.expectRevert("Price can not be 0");
        marketplace.listNFT(address(nft), tokenId, 0);

        vm.stopPrank();
    }

    /**
     * @notice Reverts if caller tries to list an NFT they don't own.
     */
    function test_RevertsIfNotOwner() public {
        vm.startPrank(user);

        address user2_ = vm.addr(3);
        uint256 tokenId_ = 1;
        nft.mint(user2_, tokenId_);

        vm.expectRevert("You are not the owner of the NFT");
        marketplace.listNFT(address(nft), tokenId_, 1);

        vm.stopPrank();
    }


    /** CANCEL LIST */

    /**
     * @notice Allows the lister to cancel their listing successfully.
     */
    function test_CancelListShouldWorkCorrectly() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);

        uint256 price_ = 1 ether;
        uint256 nftListFee_ = (price_ * listFee) / 100;

        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: nftListFee_}(address(nft), tokenId, price_);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assertEq(sellerBefore, address(0));
        assertEq(sellerAfter, user);
        assertEq(marketplace.collectedFees(), nftListFee_);

        marketplace.cancelList(address(nft), tokenId);
        (address sellerAfter2,,,) = marketplace.listing(address(nft), tokenId);
        assert(sellerAfter2 == address(0));

        vm.stopPrank();
    }

    /**
     * @notice Reverts if someone other than the lister tries to cancel the listing.
     */
    function test_CancelListRevertsIfNotOwner() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);

        uint256 price_ = 1 ether;
        uint256 nftListFee_ = (price_ * listFee) / 100;

        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: nftListFee_}(address(nft), tokenId, price_);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assertEq(sellerBefore, address(0));
        assertEq(sellerAfter, user);
        assertEq(marketplace.collectedFees(), nftListFee_);

        vm.stopPrank();

        address user2 = vm.addr(3);

        vm.expectRevert("You are not the listing owner");
        
        vm.startPrank(user2);
        marketplace.cancelList(address(nft), tokenId);

        vm.stopPrank();
    }


    /** BUY NFT */

    /**
     * @notice Completes a successful NFT purchase.
     * @dev Verifies:
     * - The NFT is removed from the listing.
     * - Ownership of the NFT is transferred.
     * - Seller receives the correct amount of ETH.
     */
    function test_ShouldBuyNFTCorrectly() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);

        uint256 price = 1e18;
        uint256 nftListFee_ = (price * listFee) / 100;

        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: nftListFee_}(address(nft), tokenId, price);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user );
        nft.approve(address(marketplace), tokenId);

        vm.stopPrank();

        address user2 = vm.addr(3);
        vm.deal(user2, 5 ether);
        vm.startPrank(user2);
        
        uint256 nftBuyFee_ = (price * buyFee) / 100;

        (address sellerBefore2,,,) = marketplace.listing(address(nft), tokenId);
        address ownerBefore = nft.ownerOf(tokenId);
        marketplace.buyNFT{value: price + nftBuyFee_}(address(nft), tokenId);
        (address sellerAfter2,,,) = marketplace.listing(address(nft), tokenId);
        address ownerAfter = nft.ownerOf(tokenId);
        uint256 balanceAfter = address(user2).balance;

        assert(sellerBefore2 == user && sellerAfter2 == address(0));
        assert(ownerBefore == user && ownerAfter == user2);
        // assert(balanceAfter == balanceBefore + price);
        assertEq(balanceAfter, 5 ether - nftBuyFee_ - price);
        assertEq(marketplace.collectedFees(), nftListFee_ + nftBuyFee_);

        vm.stopPrank();
    }

    /**
     * @notice Reverts when trying to buy an NFT that is not listed.
     */
    function test_RevertsIfBuyUnlistedNFT() public {
        address user2 = vm.addr(3);        
        vm.startPrank(user2);

        vm.expectRevert("Listing not exists");
        marketplace.buyNFT(address(nft), tokenId);

        vm.stopPrank();
    }

    /**
     * @notice Reverts when the buyer sends incorrect payment amount.
     * @dev List price is 1 ether, but buyer sends 1 wei less.
     */
    function test_RevertsIfBuyWithIncorrectPay() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);

        uint256 price = 1e18;
        uint256 nftListFee_ = (price * listFee) / 100;

        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: nftListFee_}(address(nft), tokenId, price);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user );

        vm.stopPrank();

        address user2 = vm.addr(3);
        vm.deal(user2, price);
        vm.startPrank(user2);

        vm.expectRevert("Incorrect price");
        marketplace.buyNFT{value: price - 1}(address(nft), tokenId);

        vm.stopPrank();
    }
    
    /**
     * @notice Allows the owner to withdraw collected fees
     */
    function test_withdrawFees() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);

        uint256 price = 1e18;
        uint256 nftListFee_ = (price * listFee) / 100;

        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: nftListFee_}(address(nft), tokenId, price);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user );

        vm.stopPrank();

        uint256 ownerBalanceBefore = deployer.balance;

        vm.startPrank(deployer);

        marketplace.withdrawFees();
        uint256 ownerBalanceAfter = deployer.balance;
        
        assertEq(ownerBalanceAfter, ownerBalanceBefore + nftListFee_);
        assertEq(marketplace.collectedFees(), 0);

        vm.stopPrank();
    }

    /**
     * @notice Should revert if there are not collected fees to withdraw
     */
    function test_RevertsIfNotFeesToWithdraw() public {
        vm.startPrank(deployer);

        vm.expectRevert("No fees to withdraw");
        marketplace.withdrawFees();
        

        vm.stopPrank();
    }

    /**
     * @notice Should revert if not the owner attempts to withdraw collected fees
     */
    function test_RevertsIfNotOwnerWithdraw() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);

        uint256 price = 1e18;
        uint256 nftListFee_ = (price * listFee) / 100;

        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: nftListFee_}(address(nft), tokenId, price);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user );

        vm.expectRevert();
        marketplace.withdrawFees();
        
        vm.stopPrank();
    }

    /**
     * @notice Allows owner to modify the list fee
     */
    function test_setListFeeCorrectly() public {
        vm.startPrank(deployer);
        
        uint256 newListFee_ = 2;
        marketplace.setListFee(newListFee_);
        assertEq(marketplace.listFee(), newListFee_);

        vm.stopPrank();
    }

    /**
     * @notice Reverts if not the owner attempts to modify the list fee
     */
    function test_setListFeeRevertsIfNotOwner() public {
        vm.startPrank(user);
        
        vm.expectRevert();
        uint256 newListFee_ = 2;
        marketplace.setListFee(newListFee_);

        vm.stopPrank();
    }

    /**
     * @notice Reverts if the setted fee is to high
     */
    function test_revertsIfListFeeToHigh() public {
        vm.startPrank(deployer);

        vm.expectRevert("List fee to high");
        uint256 newListFee_ = 110;
        marketplace.setListFee(newListFee_);

        vm.stopPrank();
    }


    /**
     * @notice Allows owner to modify the buy fee
     */
    function test_setBuyFeeCorrectly() public {
        vm.startPrank(deployer);
        
        uint256 newBuyFee_ = 2;
        marketplace.setBuyFee(newBuyFee_);
        assertEq(marketplace.buyFee(), newBuyFee_);

        vm.stopPrank();
    }

    /**
     * @notice Reverts if not the owner attempts to modify the buy fee
     */
    function test_setBuyFeeRevertsIfNotOwner() public {
        vm.startPrank(user);
        
        vm.expectRevert();
        uint256 newBuyFee_ = 2;
        marketplace.setBuyFee(newBuyFee_);

        vm.stopPrank();
    }

    /**
     * @notice Reverts if the setted buy fee is to high
     */
    function test_revertsIfBuytFeeToHigh() public {
        vm.startPrank(deployer);

        vm.expectRevert("Buy fee to high");
        uint256 newBuyFee_ = 110;
        marketplace.setBuyFee(newBuyFee_);

        vm.stopPrank();
    }
/// @notice Reverts if listing an NFT while the contract is paused
function test_ListNFTShouldFailWhenPaused() public {
    vm.deal(user, 1 ether);
    vm.startPrank(user);

    uint256 price = 1 ether;
    uint256 fee = (price * marketplace.listFee()) / 100;

    vm.stopPrank();

    vm.prank(deployer);
    marketplace.pause();

    vm.startPrank(user);
    vm.expectRevert();
    marketplace.listNFT{value: fee}(address(nft), tokenId, price);
    vm.stopPrank();
}

/// @notice Reverts if a non-owner tries to pause the contract
function test_PauseShouldRevertIfNotOwner() public {
    address attacker = vm.addr(3);
    vm.expectRevert();
    vm.prank(attacker);
    marketplace.pause();
}

/// @notice Reverts if a non-owner tries to unpause the contract
function test_UnpauseShouldRevertIfNotOwner() public {
    address attacker = vm.addr(3);
    vm.expectRevert();
    vm.prank(attacker);
    marketplace.unpause();
}

}