// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ZKPToken} from "../src/ZKPToken.sol";
import {SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract CrossChainTransferScript is Script {
    using OptionsBuilder for bytes;
    address BSC_CONTRACT = vm.envAddress("BSC_CONTRACT_TESTNET"); // BSC

    // LayerZero Chain IDs
    uint32 BASE_CHAIN_ID = uint32(vm.envUint("BASE_CHAIN_ID"));

    address RECEIVER_BASE_ADDRESS = vm.envAddress("RECEIVER_BASE_ADDRESS");

    function run() public {
        console2.log("Transferring BSC to BASE...");

        vm.createSelectFork("bsc");

        uint256 privateKey = vm.envUint("SENDER_BSC_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        ZKPToken bscContract = ZKPToken(BSC_CONTRACT);

        uint256 amount = 800 * 1e18; // 800 ZKPToken

        bytes memory extraOptions = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(200_000, 0);

        SendParam memory sendParam = SendParam({
            dstEid: BASE_CHAIN_ID,
            to: bytes32(uint256(uint160(RECEIVER_BASE_ADDRESS))),
            amountLD: amount,
            minAmountLD: (amount * 95) / 100,
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });

        MessagingFee memory estimatedFee = bscContract.quoteSend(
            sendParam,
            false
        );
        console2.log("Estimated native fee:", estimatedFee.nativeFee);
        console2.log("Estimated lzToken fee:", estimatedFee.lzTokenFee);

        bscContract.send{value: estimatedFee.nativeFee}(
            sendParam,
            estimatedFee,
            payable(vm.addr(privateKey)) // refund address
        );

        console2.log("Cross-chain transfer initiated!");

        vm.stopBroadcast();
    }
}
