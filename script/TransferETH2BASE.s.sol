// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ZKPToken} from "../src/ZKPToken.sol";
import {SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract CrossChainTransferScript is Script {
    using OptionsBuilder for bytes;
    address ETH_CONTRACT = vm.envAddress("ETH_CONTRACT"); // ETH

    // LayerZero Chain IDs
    uint32 BASE_CHAIN_EID = uint32(vm.envUint("BASE_CHAIN_EID"));

    address RECEIVER_BASE_ADDRESS = vm.envAddress("RECEIVER_BASE_ADDRESS");

    function run() public {
        console2.log("Transferring ETH to BASE...");

        vm.createSelectFork("eth");

        uint256 privateKey = vm.envUint("SENDER_ETH_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        ZKPToken ethContract = ZKPToken(ETH_CONTRACT);

        uint256 amount = 200 * 1e18; // 200 ZKPToken

        bytes memory extraOptions = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(200_000, 0);

        SendParam memory sendParam = SendParam({
            dstEid: BASE_CHAIN_EID,
            to: bytes32(uint256(uint160(RECEIVER_BASE_ADDRESS))),
            amountLD: amount,
            minAmountLD: (amount * 95) / 100,
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });

        MessagingFee memory estimatedFee = ethContract.quoteSend(
            sendParam,
            false
        );
        console2.log("Estimated native fee:", estimatedFee.nativeFee);
        console2.log("Estimated lzToken fee:", estimatedFee.lzTokenFee);

        ethContract.send{value: estimatedFee.nativeFee}(
            sendParam,
            estimatedFee,
            payable(vm.addr(privateKey)) // refund address
        );

        console2.log("Cross-chain transfer initiated!");

        vm.stopBroadcast();
    }
}
