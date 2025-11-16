# ZKP Token Contract

A cross-chain ERC20 token implementation for zkPass, built with LayerZero's Omnichain Fungible Token (OFT) standard. This token supports seamless transfers between BSC and Base networks while maintaining ERC20 compatibility, gasless approvals via ERC20Permit, and governance capabilities through ERC20Votes.

## Features

- **Cross-Chain Functionality**: Seamless token transfers between BSC and Base networks using LayerZero v2
- **ERC20 Standard**: Full ERC20 token implementation with standard transfer, approve, and allowance functions
- **ERC20Permit**: Gasless token approvals using EIP-2612 permit signatures
- **ERC20Votes**: Governance-ready token with voting delegation capabilities
- **Supply Cap**: Fixed supply cap of 1 billion tokens (1,000,000,000 ZKP)
- **Deterministic Deployment**: Uses CREATE2 factory for predictable contract addresses
- **Ownable**: Access control through OpenZeppelin's Ownable pattern

## Architecture

### Contracts

- **ZKPToken**: Main token contract that combines OFT, ERC20Permit, and ERC20Votes
- **Factory**: CREATE2 factory for deterministic contract deployment

### Token Details

- **Name**: zkPass
- **Symbol**: ZKP
- **Decimals**: 18
- **Total Supply Cap**: 1,000,000,000 ZKP
- **Initial Minting**: Only occurs on the specified minting chain (typically BSC)

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (latest version)
- Node.js and npm (for dependencies)
- Access to BSC and Base RPC endpoints

## Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd zkPass-Token-Contract
```

2. Install dependencies:

```bash
forge install
```

## Configuration

Create a `.env` file in the root directory with the following variables:

```env
# Private Keys
PRIVATE_KEY=your_private_key_here
SENDER_BSC_PRIVATE_KEY=your_bsc_private_key_here
SENDER_BASE_PRIVATE_KEY=your_base_private_key_here

# Contract Addresses
BSC_CONTRACT=0x...
BASE_CONTRACT=0x...
MULTISIG_TREASURY=0x...

# LayerZero Configuration
LAYERZERO_ENDPOINT=0x...
BSC_CHAIN_ID=30110
BASE_CHAIN_ID=30184
MINTING_CHAIN_ID=97

# Receiver Addresses
RECEIVER_BSC_ADDRESS=0x...
RECEIVER_BASE_ADDRESS=0x...
```

**Note**: LayerZero Chain IDs:

- BSC: 30102
- Base: 30184

## Usage

### Build

Compile the contracts:

```bash
forge build
```

### Test

Run the test suite:

```bash
forge test
```

Run tests with verbose output:

```bash
forge test -vvv
```

### Format

Format the code:

```bash
forge fmt
```

### Gas Snapshots

Generate gas usage snapshots:

```bash
forge snapshot
```

## Deployment

### Deploy to Multiple Chains

Deploy the ZKPToken contract to both BSC and Base networks:

```bash
forge script script/ZKPToken.s.sol:DeployZKPTokenScript --rpc-url bsc --private-key $PRIVATE_KEY --broadcast
```

Or deploy to a specific chain:

```bash
# Deploy to BSC
forge script script/ZKPToken.s.sol:DeployZKPTokenScript --rpc-url bsc --private-key $PRIVATE_KEY --broadcast

# Deploy to Base
forge script script/ZKPToken.s.sol:DeployZKPTokenScript --rpc-url base --private-key $PRIVATE_KEY --broadcast
```

### Setup Cross-Chain Peers

After deployment, configure the LayerZero peers on both chains:

**Set BASE as peer on BSC:**

```bash
forge script script/SetPeerBSC2Base.s.sol:SetPeerBSC2Base --rpc-url bsc --private-key $PRIVATE_KEY --broadcast
```

**Set BSC as peer on BASE:**

```bash
forge script script/SetPeerBase2BSC.s.sol:SetPeerBase2BSC --rpc-url base --private-key $PRIVATE_KEY --broadcast
```

## Contract Verification

After deployment, verify your contract on block explorers (e.g., BscScan, Basescan) using Forge's verification command.

### Verify on Etherscan

```bash
forge verify-contract \
    --chain-id <CHAIN_ID> \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address,address,uint256)" <LAYERZERO_ENDPOINT> <OWNER_ADDRESS> <MULTISIG_TREASURY_ADDRESS> <MINTING_CHAIN_ID>) \
    --verifier etherscan \
    --etherscan-api-key <ETHERSCAN_API_KEY> \
    --compiler-version v0.8.30 \
    <CONTRACT_ADDRESS> \
    src/ZKPToken.sol:ZKPToken
```

## Cross-Chain Transfers

### Transfer from BSC to Base

```bash
forge script script/TransferBSC2BASE.s.sol:CrossChainTransferScript --rpc-url bsc --private-key $SENDER_BSC_PRIVATE_KEY --broadcast
```

### Transfer from Base to BSC

```bash
forge script script/TransferBASE2BSC.s.sol:CrossChainTransferScript --rpc-url base --private-key $SENDER_BASE_PRIVATE_KEY --broadcast
```

## Contract Functions

### Standard ERC20 Functions

- `transfer(address to, uint256 amount)`: Transfer tokens to another address
- `transferFrom(address from, address to, uint256 amount)`: Transfer tokens on behalf of another address
- `approve(address spender, uint256 amount)`: Approve a spender to transfer tokens
- `balanceOf(address account)`: Get token balance of an account
- `allowance(address owner, address spender)`: Get remaining allowance

### ERC20Permit Functions

- `permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)`: Approve tokens via signature
- `nonces(address owner)`: Get the current nonce for permit signatures

### ERC20Votes Functions

- `delegate(address delegatee)`: Delegate voting power to another address
- `delegates(address account)`: Get the current delegate for an account
- `getVotes(address account)`: Get current voting power
- `getPastVotes(address account, uint256 blockNumber)`: Get past voting power

### LayerZero OFT Functions

- `send(SendParam calldata _sendParam, MessagingFee calldata _fee, address payable _refundAddress)`: Send tokens cross-chain
- `quoteSend(SendParam calldata _sendParam, bool _payInLzToken)`: Estimate cross-chain transfer fees
- `setPeer(uint32 _eid, bytes32 _peer)`: Set LayerZero peer for cross-chain communication

## Testing

The test suite covers:

- Constructor validation and initial supply minting
- Standard ERC20 transfer and approval functionality
- ERC20Permit signature-based approvals
- ERC20Votes delegation and voting power
- Supply cap enforcement
- Edge cases (zero transfers, self-transfers, etc.)

Run specific test functions:

```bash
forge test --match-test test_Constructor_SetsCorrectValues
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [LayerZero Documentation](https://docs.layerzero.network/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

## Support

For issues, questions, or contributions, please open an issue or pull request on the repository.
