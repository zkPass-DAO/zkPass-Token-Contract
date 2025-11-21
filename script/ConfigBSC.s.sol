// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {console2} from "forge-std/console2.sol";
import {ZKPToken} from "../src/ZKPToken.sol";

contract ConfigBSC is Script {
    using OptionsBuilder for bytes;

    address BASE_CONTRACT = vm.envAddress("BASE_CONTRACT");
    address BSC_CONTRACT = vm.envAddress("BSC_CONTRACT");
    address ETH_CONTRACT = vm.envAddress("ETH_CONTRACT");

    // LayerZero Chain IDs
    uint32 BASE_CHAIN_EID = uint32(vm.envUint("BASE_CHAIN_EID"));
    uint32 BSC_CHAIN_EID = uint32(vm.envUint("BSC_CHAIN_EID"));
    uint32 ETH_CHAIN_EID = uint32(vm.envUint("ETH_CHAIN_EID"));

    address ENDPOINT = vm.envAddress("LAYERZERO_ENDPOINT"); // all endpoint addresses are the same on each chain

    function SetLibraries() internal {
        console2.log("SetLibraries for BSC...");

        address sendLib = vm.envAddress("BSC_SEND_LIB_ADDRESS"); // SendUln302 address
        address receiveLib = vm.envAddress("BSC_RECEIVE_LIB_ADDRESS"); // ReceiveUln302 address

        // Chain configurations
        uint32 gracePeriod = uint32(vm.envUint("GRACE_PERIOD")); // Grace period for library switch

        ILayerZeroEndpointV2(ENDPOINT).setSendLibrary(
            BSC_CONTRACT,
            BASE_CHAIN_EID, // Destination chain EID -> BASE
            sendLib
        );

        ILayerZeroEndpointV2(ENDPOINT).setSendLibrary(
            BSC_CONTRACT,
            ETH_CHAIN_EID, // Destination chain EID -> ETH
            sendLib
        );

        ILayerZeroEndpointV2(ENDPOINT).setReceiveLibrary(
            BSC_CONTRACT,
            BSC_CHAIN_EID, // Source chain EID -> BSC
            receiveLib,
            gracePeriod
        );
    }

    function SetSendConfig() internal {
        console2.log("SetSendConfig for BSC...");

        uint32 EXECUTOR_CONFIG_TYPE = 1;
        uint32 ULN_CONFIG_TYPE = 2;

        address[] memory bscDVNs = new address[](3);
        bscDVNs[0] = vm.envAddress("BSC_DVN_1");
        bscDVNs[1] = vm.envAddress("BSC_DVN_2");
        bscDVNs[2] = vm.envAddress("BSC_DVN_3");

        UlnConfig memory bscUln = UlnConfig({
            confirmations: 15, // minimum block confirmations required on A before sending to B
            requiredDVNCount: 3, // number of DVNs required
            optionalDVNCount: type(uint8).max, // optional DVNs count, uint8
            optionalDVNThreshold: 0, // optional DVN threshold
            requiredDVNs: bscDVNs, // sorted list of required DVN addresses
            optionalDVNs: new address[](0) // sorted list of optional DVNs
        });

        address bscExecutor = vm.envAddress("BSC_EXECUTOR");
        ExecutorConfig memory bscExec = ExecutorConfig({
            maxMessageSize: 10000, // max bytes per cross-chain message
            executor: bscExecutor // address that pays destination execution fees on B
        });

        bytes memory encodedBscUln = abi.encode(bscUln);
        bytes memory encodedBscExec = abi.encode(bscExec);

        // config for BASE
        SetConfigParam[] memory baseSendParams = new SetConfigParam[](2);
        baseSendParams[0] = SetConfigParam(
            BASE_CHAIN_EID,
            EXECUTOR_CONFIG_TYPE,
            encodedBscExec
        );
        baseSendParams[1] = SetConfigParam(
            BASE_CHAIN_EID,
            ULN_CONFIG_TYPE,
            encodedBscUln
        );

        address bscSendLib = vm.envAddress("BSC_SEND_LIB_ADDRESS");
        ILayerZeroEndpointV2(ENDPOINT).setConfig(
            BSC_CONTRACT,
            bscSendLib,
            baseSendParams
        );

        // config for ETH
        SetConfigParam[] memory ethSendParams = new SetConfigParam[](2);
        ethSendParams[0] = SetConfigParam(
            ETH_CHAIN_EID,
            EXECUTOR_CONFIG_TYPE,
            encodedBscExec
        );
        ethSendParams[1] = SetConfigParam(
            ETH_CHAIN_EID,
            ULN_CONFIG_TYPE,
            encodedBscUln
        );

        ILayerZeroEndpointV2(ENDPOINT).setConfig(
            BSC_CONTRACT,
            bscSendLib,
            ethSendParams
        );
    }

    function SetReceiveConfigForBASE() internal {
        console2.log("SetReceiveConfig for BASE...");

        uint32 RECEIVE_CONFIG_TYPE = 2;

        address[] memory baseDVNs = new address[](3);
        baseDVNs[0] = vm.envAddress("BASE_DVN_1");
        baseDVNs[1] = vm.envAddress("BASE_DVN_2");
        baseDVNs[2] = vm.envAddress("BASE_DVN_3");

        UlnConfig memory baseUln = UlnConfig({
            confirmations: 15, // minimum block confirmations required on A before sending to B
            requiredDVNCount: 3, // number of DVNs required
            optionalDVNCount: type(uint8).max, // optional DVNs count, uint8
            optionalDVNThreshold: 0, // optional DVN threshold
            requiredDVNs: baseDVNs, // sorted list of required DVN addresses
            optionalDVNs: new address[](0) // sorted list of optional DVNs
        });

        bytes memory encodedBaseUln = abi.encode(baseUln);

        SetConfigParam[] memory baseReceiveParams = new SetConfigParam[](1);
        baseReceiveParams[0] = SetConfigParam(
            BSC_CHAIN_EID,
            RECEIVE_CONFIG_TYPE,
            encodedBaseUln
        );

        address baseReceiveLib = vm.envAddress("BASE_RECEIVE_LIB_ADDRESS");
        ILayerZeroEndpointV2(ENDPOINT).setConfig(
            BASE_CONTRACT,
            baseReceiveLib,
            baseReceiveParams
        );
    }

    function SetReceiveConfigForETH() internal {
        console2.log("SetReceiveConfig for ETH...");

        uint32 RECEIVE_CONFIG_TYPE = 2;

        address[] memory ethDVNs = new address[](3);
        ethDVNs[0] = vm.envAddress("ETH_DVN_1");
        ethDVNs[1] = vm.envAddress("ETH_DVN_2");
        ethDVNs[2] = vm.envAddress("ETH_DVN_3");

        UlnConfig memory ethUln = UlnConfig({
            confirmations: 15, // minimum block confirmations required on A before sending to B
            requiredDVNCount: 3, // number of DVNs required
            optionalDVNCount: type(uint8).max, // optional DVNs count, uint8
            optionalDVNThreshold: 0, // optional DVN threshold
            requiredDVNs: ethDVNs, // sorted list of required DVN addresses
            optionalDVNs: new address[](0) // sorted list of optional DVNs
        });

        bytes memory encodedEthUln = abi.encode(ethUln);

        SetConfigParam[] memory ethReceiveParams = new SetConfigParam[](1);
        ethReceiveParams[0] = SetConfigParam(
            BSC_CHAIN_EID,
            RECEIVE_CONFIG_TYPE,
            encodedEthUln
        );

        address ethReceiveLib = vm.envAddress("ETH_RECEIVE_LIB_ADDRESS");
        ILayerZeroEndpointV2(ENDPOINT).setConfig(
            ETH_CONTRACT,
            ethReceiveLib,
            ethReceiveParams
        );
    }

    function SetPeerConfig() internal {
        console2.log("SetPeerConfig for BSC...");

        ZKPToken bscContract = ZKPToken(BSC_CONTRACT);

        // set peer for BASE
        bscContract.setPeer(
            BASE_CHAIN_EID,
            bytes32(uint256(uint160(BASE_CONTRACT)))
        );

        // set peer for ETH
        bscContract.setPeer(
            ETH_CHAIN_EID,
            bytes32(uint256(uint160(ETH_CONTRACT)))
        );
    }

    function SetEnforcedOptions() internal {
        console2.log("SetEnforcedOptions for BSC...");

        uint16 SEND = 1;

        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(80000, 0);

        EnforcedOptionParam[]
            memory enforcedOptions = new EnforcedOptionParam[](2);

        // Set enforced options for first destination -> BASE
        enforcedOptions[0] = EnforcedOptionParam({
            eid: BASE_CHAIN_EID,
            msgType: SEND,
            options: options
        });

        // Set enforced options for second destination -> ETH
        enforcedOptions[1] = EnforcedOptionParam({
            eid: ETH_CHAIN_EID,
            msgType: SEND,
            options: options
        });

        ZKPToken(BSC_CONTRACT).setEnforcedOptions(enforcedOptions);
    }

    function run() public {
        console2.log("Setting Config for BSC...");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // config for BSC
        vm.createSelectFork("bsc");

        vm.startBroadcast(privateKey);

        SetLibraries();
        SetSendConfig();
        SetPeerConfig();
        SetEnforcedOptions();

        vm.stopBroadcast();

        // config for receive on BASE
        vm.createSelectFork("base");
        vm.startBroadcast(privateKey);

        SetReceiveConfigForBASE();

        vm.stopBroadcast();

        // config for receive on ETH
        vm.createSelectFork("eth");
        vm.startBroadcast(privateKey);

        SetReceiveConfigForETH();

        vm.stopBroadcast();
    }
}
