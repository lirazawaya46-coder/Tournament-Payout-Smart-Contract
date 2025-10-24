# 🏆 Tournament Payout Smart Contract

> **Revolutionizing esports prize distribution with blockchain transparency and automation** ⚡

## 🎮 Overview

The Tournament Payout Smart Contract eliminates the traditional pain points of esports tournament prize distribution by:

- 🔒 **Locking prize pools** in smart contracts before events begin
- ⚡ **Instant automated payouts** to verified winners
- 🛡️ **Eliminating disputes** through transparent blockchain records
- 🚫 **Removing manual intervention** from reward distribution

## ✨ Features

- **🎯 Tournament Management**: Create and manage tournaments with customizable parameters
- **💰 Secure Prize Pools**: Entry fees automatically locked in contract escrow
- **👥 Participant Registration**: Seamless registration with entry fee payment
- **🏅 Winner Verification**: Organizer-controlled winner verification system
- **💸 Automated Payouts**: Instant prize distribution to verified winners
- **🆘 Emergency Controls**: Safety mechanisms for unexpected situations

## 🔧 Core Functions

### Tournament Creation
```clarity
(create-tournament 
    "My Tournament"     ;; Tournament name
    u1000000           ;; Entry fee (1 STX in microSTX)
    u16                ;; Max participants
    u1000              ;; Duration in blocks
    u50                ;; 1st place percentage
    u30                ;; 2nd place percentage
    u20)               ;; 3rd place percentage
```

### Registration
```clarity
(register-participant u1) ;; Tournament ID
```

### Tournament Lifecycle
```clarity
(start-tournament u1)     ;; Start tournament
(end-tournament u1)       ;; End tournament
(verify-winners u1        ;; Verify winners
    'ST1WINNER1
    'ST2WINNER2
    'ST3WINNER3)
(distribute-prizes u1)    ;; Distribute prizes
```

## 📊 Tournament Status Flow

```
"registration" → "active" → "ended" → "completed"
        ↓            ↓          ↓           ↓
   📝 Sign-up    🎮 Playing  🏁 Finished  💰 Paid
```

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet with STX tokens
- Basic understanding of Clarity smart contracts

### Quick Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Tournament-Payout-Smart-Contract
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Run tests**
   ```bash
   npm test
   ```

4. **Deploy contract**
   ```bash
   clarinet deploy --testnet
   ```

## 💡 Usage Examples

### Creating a Tournament

```typescript
// Create a tournament for 16 players with 1 STX entry fee
const result = await contractCall({
    contractAddress: 'ST1234...',
    contractName: 'tournament-payout',
    functionName: 'create-tournament',
    functionArgs: [
        stringAsciiCV("Fortnite Championship"),
        uintCV(1000000), // 1 STX in microSTX
        uintCV(16),      // Max 16 participants
        uintCV(2000),    // ~2 weeks duration
        uintCV(50),      // 50% to 1st place
        uintCV(30),      // 30% to 2nd place
        uintCV(20)       // 20% to 3rd place
    ]
});
```

### Registering for a Tournament

```typescript
const registration = await contractCall({
    contractAddress: 'ST1234...',
    contractName: 'tournament-payout',
    functionName: 'register-participant',
    functionArgs: [uintCV(1)] // Tournament ID
});
```

## 🔍 Read-Only Functions

- `get-tournament(uint)` - Get tournament details
- `get-participant-info(uint, principal)` - Get participant status
- `get-tournament-winners(uint)` - Get winner information
- `get-tournament-balance(uint)` - Get tournament prize pool
- `is-tournament-active(uint)` - Check if tournament is active
- `can-register(uint)` - Check if registration is open

## 🛡️ Security Features

- **👑 Authorization Controls**: Only organizers can manage tournaments
- **💎 Escrow Protection**: Funds locked until verified payout
- **🔄 State Validation**: Strict tournament lifecycle enforcement
- **⚡ Emergency Withdrawals**: Contract owner safety mechanism
- **✅ Winner Verification**: Prevents unauthorized payouts

## 📋 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| `u1` | `ERR_NOT_AUTHORIZED` | Caller lacks permission |
| `u2` | `ERR_TOURNAMENT_NOT_FOUND` | Invalid tournament ID |
| `u3` | `ERR_TOURNAMENT_ACTIVE` | Operation not allowed in current state |
| `u4` | `ERR_TOURNAMENT_ENDED` | Tournament already ended |
| `u5` | `ERR_INSUFFICIENT_FUNDS` | Not enough STX |
| `u6` | `ERR_ALREADY_PAID` | Prizes already distributed |
| `u7` | `ERR_INVALID_WINNER` | Winner not a participant |
| `u8` | `ERR_TOURNAMENT_NOT_ENDED` | Tournament still active |
| `u9` | `ERR_INVALID_PRIZE_STRUCTURE` | Prize percentages don't add to 100% |

## 🧪 Testing

```bash
# Run all tests
npm test

# Check contract syntax
clarinet check

# Console testing
clarinet console
```

## 🌟 Benefits for Esports

### For Tournament Organizers
- 📈 **Increased Trust**: Transparent prize handling builds credibility
- ⏱️ **Time Savings**: Automated payouts reduce administrative overhead
- 💰 **Cost Reduction**: No need for escrow services or manual processing

### For Players
- ✅ **Guaranteed Payouts**: Prizes locked and guaranteed from day one
- ⚡ **Instant Rewards**: Receive winnings immediately after verification
- 🔍 **Full Transparency**: All transactions visible on blockchain

### For the Ecosystem
- 🎯 **Higher Participation**: Players more likely to join guaranteed tournaments
- 🏆 **Professional Standards**: Elevates tournament quality and reputation
- 📊 **Data Integrity**: Immutable record of all tournament activities

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📜 License

This project is licensed under the MIT License.

## 🔗 Resources

- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)
- [Stacks Blockchain](https://www.stacks.co/)

---

**Built with ❤️ for the esports community** 🎮

# Tournament Payout Smart Contract

