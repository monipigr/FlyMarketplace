# 🛒 FLYMarketplace

## 📝 Overview

**FLYMarketplace** s a professional smart contract for listing, buying, and canceling ERC-721 NFTs with monetization mechanisms and production-ready controls, such as pausable states, owner-only access, and proper ETH flow mechanisms. It introduces dynamic fees, withdrawal systems, pausability, and extensive testing using Foundry.

## ✨ Features

- 🏧 **List NFTs:** Sellers can list NFTs for a specific price and pay a configurable listing fee.
- 💰 **Buy NFTs:** Buyers can purchase NFTs by paying the sale price plus a configurable fee.
- ❌ **Cancel Listings:** Sellers can cancel their own active listings.
- 🔐 **Security Measures**:
  - Reentrancy protection using OpenZeppelin’s `ReentrancyGuard`
  - Pausable mechanism for emergency stops
  - Ownership-based access control using `Ownable`
  - 💸 **Fee Management**:
  - Dynamic `listFee` and `buyFee` managed by the owner
  - Accumulated fees can be withdrawn via `withdrawFees()`
- 📢 **Events**: Emits `NFTListed`, `NFTSold`, `NFTCanceled`, `NFTFeeCollected` and `WithdrawnFees`.

## 🧩🛡️ Contract Logic & Security Practices

- **Storage Layout**: Nested `mapping(address => mapping(uint256 => Listing))` for direct NFT lookups.
- **Structs**:
  - `Listing`: Stores seller, NFT address, token ID, and price.
- **Events**:
  - `NFTListed`, `NFTSold`, `NFTCanceled`, `NFTFeeCollected` and `WithdrawnFees` to track contract activity.
- **Modifiers & Checks**:
  - Ownership verification with `IERC721.ownerOf`
  - `ReentrancyGuard` used to avoid reentrancy attacks
- **Design Patterns**:
  - CEI (Checks-Effects-Interactions)
  - Pull payment patern using `.call{value: msg.value}("")`
- **Security Extensions**:
  - `pause()`and `unpause()` for emergency control.
  - `onlyOwner` protectioin on fee setters and withdraw function

---

## 🧪 Testing

The contract includes a complete suite of unit tests using Foundry’s `forge-std/Test.sol`. Tests validate core functionalities, expected behavior, negative cases, and edge cases:

| Test Function                              | Purpose                                   |
| ------------------------------------------ | ----------------------------------------- |
| `test_MintNFT()`                           | Verifies NFT minting in test setup        |
| `test_ListNFTCorrectly()`                  | Confirms correct listing with fee         |
| `test_ShouldBuyNFTCorrectly()`             | Full purchase flow with balance checks    |
| `test_CancelListShouldWorkCorrectly()`     | Cancels listing by correct seller         |
| `test_RevertsIfIncorrectFee()`             | Rejects incorrect listing fee             |
| `test_RevertsIfPriceIsZero()`              | Rejects zero price listing                |
| `test_RevertsIfNotOwner()`                 | Prevents listing by non-owner             |
| `test_CancelListRevertsIfNotOwner()`       | Only lister can cancel listing            |
| `test_RevertsIfBuyUnlistedNFT()`           | Prevents purchase of unlisted NFT         |
| `test_RevertsIfBuyWithIncorrectPay()`      | Validates correct `msg.value` on `buyNFT` |
| `test_withdrawFees()`                      | Owner withdraws accumulated fees          |
| `test_RevertsIfNotFeesToWithdraw()`        | Prevents withdrawing zero fees            |
| `test_RevertsIfNotOwnerWithdraw()`         | Rejects fee withdrawal by non-owner       |
| `test_setListFeeCorrectly()`               | Sets new list fee by owner                |
| `test_setBuyFeeCorrectly()`                | Sets new buy fee by owner                 |
| `test_revertsIfListFeeToHigh()`            | Rejects list fee above limit              |
| `test_revertsIfBuytFeeToHigh()`            | Rejects buy fee above limit               |
| `test_setListFeeRevertsIfNotOwner()`       | Only owner can change list fee            |
| `test_setBuyFeeRevertsIfNotOwner()`        | Only owner can change buy fee             |
| `test_PauseAndUnpauseShouldWorkForOwner()` | Owner can pause and unpause the contract  |
| `test_ListNFTShouldFailWhenPaused()`       | Listing fails if contract is paused       |
| `test_PauseShouldRevertIfNotOwner()`       | Non-owner cannot pause                    |
| `test_UnpauseShouldRevertIfNotOwner()`     | Non-owner cannot unpause                  |

## ✅ Coverage Highlights

```
forge coverage
```

> 📈 **95%+ test coverage**, including listing, cancel listing, and buying.

| File                   | % Lines        | % Statements   | % Branches     | % Funcs       |
| ---------------------- | -------------- | -------------- | -------------- | ------------- |
| src/FLYMarketplace.sol | 98.00% (49/50) | 97.83% (45/46) | 90.91% (20/22) | 100.00% (9/9) |

### 🔍 Notes:

- ETH transfer `require(success, ...)` fallback path intentionally not tested (very low risk)

> The uncovered lines do not affect contract behavior or introduce security risk.

# 🛠 Technologies Used

- **Solidity**: Solidity `^0.8.24`
- **Testing**: Foundry (Forge)
- **NFT Standard**: ERC721
- **Security**: ReentrancyGuard, Ownable, Pausable (OpenZeppelin)

## 🔧 How to Use

### Prerequisites

- Install [Foundry](https://book.getfoundry.sh/)
- Install [OpenZeppelin](https://docs.openzeppelin)

### 🛠 Setup

```bash
git clone https://github.com/your-username/FLYMarketplace.git
cd FLYMarketplace
forge install
```

### Testing

```bash
forge test
forge --match-test testExample -vvvv
```

## 📜 License

This project is licensed under the MIT License.
