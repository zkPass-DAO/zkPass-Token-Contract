// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ZKPToken} from "../src/ZKPToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {EndpointV2Mock} from "../lib/devtools/packages/test-devtools-evm-foundry/contracts/mocks/EndpointV2Mock.sol";

contract ZKPTokenTest is Test {
    ZKPToken public token;
    EndpointV2Mock public lzEndpoint;
    address public owner;
    address public treasury;
    address public user1;
    address public user2;

    uint256 public constant SUPPLY_CAP = 1_000_000_000 * 10 ** 18;
    uint256 public constant CHAIN_ID_97 = 97;
    uint256 public constant OTHER_CHAIN_ID = 1; // Different from CHAIN_ID_97

    function setUp() public {
        // Setup addresses
        owner = address(this);
        treasury = address(0x5678);
        user1 = address(0x9ABC);
        user2 = address(0xDEF0);

        // Deploy mock LayerZero endpoint
        lzEndpoint = new EndpointV2Mock(1, owner);

        // Deploy token (default chainid is not 97, so no minting)
        // Pass OTHER_CHAIN_ID as mintingChainId to ensure no minting on default chain
        token = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            OTHER_CHAIN_ID
        );
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsCorrectValues() public view {
        assertEq(token.name(), "zkPass");
        assertEq(token.symbol(), "ZKP");
        assertEq(token.owner(), owner);
    }

    function test_Constructor_RevertsWhenTreasuryIsZero() public {
        vm.expectRevert(bytes("MultiSigTreasury cannot be zero address"));
        new ZKPToken(address(lzEndpoint), owner, address(0), CHAIN_ID_97);
    }

    function test_Constructor_OnChainId97_MintsToTreasury() public {
        // Switch to chainid 97
        vm.chainId(CHAIN_ID_97);

        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        assertEq(token97.SUPPLY_CAP(), SUPPLY_CAP);
        assertEq(token97.totalSupply(), SUPPLY_CAP);
        assertEq(token97.balanceOf(treasury), SUPPLY_CAP);
    }

    function test_Constructor_OnOtherChain_NoMinting() public view {
        // Default chainid is not 97
        // Supply cap is always set on all chains, but no minting occurs
        assertEq(token.SUPPLY_CAP(), SUPPLY_CAP);
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(treasury), 0);
    }

    // ============ ERC20 Basic Tests ============

    function test_Transfer_OnChainId97_Succeeds() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        vm.prank(treasury);
        token97.transfer(user1, 1000 * 10 ** 18);

        assertEq(token97.balanceOf(user1), 1000 * 10 ** 18);
        assertEq(token97.balanceOf(treasury), SUPPLY_CAP - 1000 * 10 ** 18);
    }

    function test_TransferFrom_OnChainId97_Succeeds() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        vm.prank(treasury);
        token97.approve(user1, 1000 * 10 ** 18);

        vm.prank(user1);
        token97.transferFrom(treasury, user2, 1000 * 10 ** 18);

        assertEq(token97.balanceOf(user2), 1000 * 10 ** 18);
        assertEq(token97.balanceOf(treasury), SUPPLY_CAP - 1000 * 10 ** 18);
        assertEq(token97.allowance(treasury, user1), 0);
    }

    function test_Approve_SetsAllowance() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        vm.prank(treasury);
        token97.approve(user1, 1000 * 10 ** 18);

        assertEq(token97.allowance(treasury, user1), 1000 * 10 ** 18);
    }

    // ============ ERC20Permit Tests ============

    function test_Permit_Succeeds() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        uint256 privateKey = 0x123;
        address signer = vm.addr(privateKey);

        // Give signer some tokens
        vm.prank(treasury);
        token97.transfer(signer, 1000 * 10 ** 18);

        // Prepare permit
        uint256 nonce = token97.nonces(signer);
        uint256 deadline = block.timestamp + 1 days;
        bytes32 domainSeparator = token97.DOMAIN_SEPARATOR();

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                signer,
                user1,
                500 * 10 ** 18,
                nonce,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);

        // Execute permit
        token97.permit(signer, user1, 500 * 10 ** 18, deadline, v, r, s);

        assertEq(token97.allowance(signer, user1), 500 * 10 ** 18);
        assertEq(token97.nonces(signer), nonce + 1);
    }

    function test_Nonces_IncrementsAfterPermit() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        uint256 initialNonce = token97.nonces(user1);
        assertEq(initialNonce, 0);

        // After a permit, nonce should increment
        // (We'll test this with a full permit flow in test_Permit_Succeeds)
    }

    // ============ ERC20Votes Tests ============

    function test_Delegation_Succeeds() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        // Treasury delegates to user1
        vm.prank(treasury);
        token97.delegate(user1);

        assertEq(token97.delegates(treasury), user1);
    }

    function test_GetVotes_ReturnsCorrectVotes() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        // Treasury needs to delegate to itself to have votes
        vm.prank(treasury);
        token97.delegate(treasury);

        // Treasury has all tokens, so should have all votes
        assertEq(token97.getVotes(treasury), SUPPLY_CAP);

        // Transfer some tokens
        vm.prank(treasury);
        token97.transfer(user1, 1000 * 10 ** 18);

        // Votes should decrease
        assertEq(token97.getVotes(treasury), SUPPLY_CAP - 1000 * 10 ** 18);
    }

    // Note: getPastVotes testing is complex due to ERC5805 requirements
    // The basic voting functionality is tested in test_GetVotes_ReturnsCorrectVotes
    // and test_Delegation_Succeeds

    // ============ Update Tests ============

    function test_Update_TransfersTokens() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        uint256 amount = 1000 * 10 ** 18;
        vm.prank(treasury);
        token97.transfer(user1, amount);

        assertEq(token97.balanceOf(treasury), SUPPLY_CAP - amount);
        assertEq(token97.balanceOf(user1), amount);
    }

    // ============ Edge Cases ============

    function test_Transfer_ZeroAmount() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        vm.prank(treasury);
        token97.transfer(user1, 0);

        assertEq(token97.balanceOf(treasury), SUPPLY_CAP);
        assertEq(token97.balanceOf(user1), 0);
    }

    function test_Transfer_ToSelf() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        uint256 balanceBefore = token97.balanceOf(treasury);
        vm.prank(treasury);
        token97.transfer(treasury, 1000 * 10 ** 18);

        assertEq(token97.balanceOf(treasury), balanceBefore);
    }

    function test_Approve_ZeroAddress_Reverts() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        vm.prank(treasury);
        vm.expectRevert();
        token97.approve(address(0), 1000 * 10 ** 18);
    }

    // ============ Supply Cap Tests ============

    function test_SupplyCap_OnChainId97_IsSet() public {
        vm.chainId(CHAIN_ID_97);
        ZKPToken token97 = new ZKPToken(
            address(lzEndpoint),
            owner,
            treasury,
            CHAIN_ID_97
        );

        assertEq(token97.SUPPLY_CAP(), SUPPLY_CAP);
    }

    function test_SupplyCap_OnOtherChain_IsSet() public view {
        // Default chainid is not 97
        // Supply cap is always set on all chains, regardless of minting
        assertEq(token.SUPPLY_CAP(), SUPPLY_CAP);
    }
}
