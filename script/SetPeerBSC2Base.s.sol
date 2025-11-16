// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ZKPToken} from "../src/ZKPToken.sol";

contract SetPeerBSC2Base is Script {
    address BSC_CONTRACT = vm.envAddress("BSC_CONTRACT_TESTNET");
    address BASE_CONTRACT = vm.envAddress("BASE_CONTRACT_TESTNET");

    // LayerZero Chain IDs
    uint32 BASE_CHAIN_ID = uint32(vm.envUint("BASE_CHAIN_ID"));
    uint32 BSC_CHAIN_ID = uint32(vm.envUint("BSC_CHAIN_ID"));

    function run() public {
        console2.log("Setting BASE as peer on BSC...");

        vm.createSelectFork("bsc");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        ZKPToken bscContract = ZKPToken(BSC_CONTRACT);
        bscContract.setPeer(
            BASE_CHAIN_ID,
            bytes32(uint256(uint160(BASE_CONTRACT)))
        );
        console2.log("Set BASE as peer on BSC Testnet");

        vm.stopBroadcast();
    }
}
