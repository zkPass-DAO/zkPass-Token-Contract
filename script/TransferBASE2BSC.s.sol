// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ZKPToken} from "../src/ZKPToken.sol";
import {SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract CrossChainTransferScript is Script {
    using OptionsBuilder for bytes;
    address BASE_CONTRACT = vm.envAddress("BASE_CONTRACT_TESTNET"); // BASE

    // LayerZero Chain IDs
    uint32 BSC_CHAIN_ID = uint32(vm.envUint("BSC_CHAIN_ID"));

    address RECEIVER_BSC_ADDRESS = vm.envAddress("RECEIVER_BSC_ADDRESS");

    function run() public {
        console2.log("Transferring BASE to BSC...");

        vm.createSelectFork("base");

        uint256 privateKey = vm.envUint("SENDER_BASE_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        ZKPToken baseContract = ZKPToken(BASE_CONTRACT);

        uint256 amount = 400 * 1e18; // 400 ZKPToken

        bytes memory extraOptions = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(200_000, 0);

        SendParam memory sendParam = SendParam({
            dstEid: BSC_CHAIN_ID,
            to: bytes32(uint256(uint160(RECEIVER_BSC_ADDRESS))),
            amountLD: amount,
            minAmountLD: (amount * 95) / 100,
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });

        MessagingFee memory estimatedFee = baseContract.quoteSend(
            sendParam,
            false
        );
        console2.log("Estimated native fee:", estimatedFee.nativeFee);
        console2.log("Estimated lzToken fee:", estimatedFee.lzTokenFee);

        baseContract.send{value: estimatedFee.nativeFee}(
            sendParam,
            estimatedFee,
            payable(vm.addr(privateKey)) // refund address
        );

        console2.log("Cross-chain transfer initiated!");

        vm.stopBroadcast();
    }
}
