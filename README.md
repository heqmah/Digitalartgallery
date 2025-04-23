---

# 🎨 Digital Art Gallery Smart Contract

This Clarity smart contract powers a decentralized digital art gallery on the Stacks blockchain. Artists can mint digital artworks, curate their collections, and exhibit or sell their pieces directly to collectors in a trustless and transparent way.

---

## 📋 Features

- **Minting Artworks**: Artists can create new digital artworks with metadata and mark them as displayable.
- **Portfolio Tracking**: Tracks the number of artworks each artist has minted.
- **Gifting Art**: Artists can gift artworks to other users if the artwork is marked as displayable.
- **Exhibit for Sale**: Artists can list artworks for sale with a specific asking price.
- **Remove from Exhibit**: Artists can unlist their artwork from the gallery.
- **Purchase Artwork**: Collectors can buy artwork directly with STX, with commissions going to the gallery.
- **Administrative Controls**: The gallery owner can update the commission rate or transfer ownership.

---

## 🧾 Data Structures

### 🎨 `artworks`
Stores metadata about each minted artwork.
```clarity
{ 
  art-id: uint, 
  artist: principal, 
  description: (string-ascii 256), 
  minted-on: uint, 
  displayable: bool 
}
```

### 🖼 `gallery-exhibit`
Stores listings of artwork that are currently on display for sale.
```clarity
{ 
  art-id: uint, 
  asking-price: uint, 
  curator: principal, 
  on-display: bool 
}
```

### 👤 `artist-portfolio`
Tracks how many artworks each artist has minted.
```clarity
{ 
  artist: principal, 
  total-artworks: uint 
}
```

---

## ⚙️ Admin Variables

- `gallery-owner`: Address with administrative privileges.
- `next-art-id`: Counter for the next available artwork ID.
- `commission-rate`: Commission percentage (in basis points, e.g. 25 = 2.5%).

---

## 🔍 Read-Only Functions

- `fetch-art (art-id)`: Returns metadata of an artwork.
- `fetch-exhibit (art-id)`: Returns exhibit info of an artwork.
- `portfolio-summary (artist)`: Returns the number of artworks minted by an artist.
- `fetch-artist (art-id)`: Returns the current owner (artist) of a specific artwork.

---

## 🔓 Public Functions

### Minting & Gifting
- `mint-art (description, displayable)`: Mints a new artwork with a description and whether it is transferable.
- `gift-art (art-id, receiver)`: Transfers the ownership of an artwork if it's marked as displayable.

### Exhibiting & Selling
- `exhibit-art (art-id, amount)`: Lists the artwork for sale with a given price.
- `remove-exhibit (art-id)`: Removes the artwork from sale.
- `purchase-art (art-id)`: Allows a collector to buy the artwork, handling payment and ownership transfer.

---

## 🔐 Administrative Functions

- `adjust-commission (new-rate)`: Allows the gallery owner to update the commission fee (max 1000 = 100%).
- `change-gallery-owner (new-owner)`: Transfers ownership of the gallery contract.

---

## 🧪 Error Codes

| Code | Meaning |
|------|---------|
| `err u200` | Not authorized (only gallery owner or artist) |
| `err u201` | Artwork not found |
| `err u202` | Insufficient funds |
| `err u203` | Invalid price or commission rate |
| `err u204` | Already listed on exhibit |
| `err u205` | Not listed on exhibit |

---

## 💸 Economic Model

- When an artwork is sold:
  - **Artist** receives the sale price minus a small commission.
  - **Gallery owner** receives a percentage as a commission (default 2.5%).

---

## 🔐 Security Notes

- All transfers are done via `stx-transfer?` and wrapped in `try!` to handle failures safely.
- Only the original artist can list or gift their own artworks.
- Commission rate is capped to a maximum of 100% (1000 basis points).

---

## 🚀 Getting Started

To deploy and interact with this smart contract on the Stacks blockchain:

1. **Install Clarity tools** (e.g., [Clarinet](https://github.com/hirosystems/clarinet))
2. **Clone this repo**
3. **Update constants or test scenarios** as needed
4. **Deploy** on testnet or mainnet using Clarinet or the Stacks CLI

---

## 📄 License

This project is open-source and available under the MIT License.

---



