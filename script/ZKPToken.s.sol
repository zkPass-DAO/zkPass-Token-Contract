// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ZKPToken} from "../src/ZKPToken.sol";
import {Factory} from "../src/Factory.sol";

contract DeployZKPTokenScript is Script {
    address owner;
    Factory fac;

    function run() public {
        deploy("bsc");

        deploy("base");
    }

    function deploy(string memory chain) public {
        // Setup
        console2.log("Deploying ZKPToken on", chain, "...");
        vm.createSelectFork(chain);

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        fac = new Factory();
        console2.log("Factory deployed at:", address(fac));

        owner = vm.addr(privateKey);

        address multisigTreasury = vm.envAddress("MULTISIG_TREASURY");
        address layerzeroEndpoint = vm.envAddress("LAYERZERO_ENDPOINT");
        uint256 mintingChainId = vm.envUint("MINTING_CHAIN_ID");

        bytes32 salt = keccak256(abi.encodePacked("ZKPToken", owner));

        bytes memory code = abi.encodePacked(
            type(ZKPToken).creationCode,
            abi.encode(
                layerzeroEndpoint,
                owner,
                multisigTreasury,
                mintingChainId
            )
        );

        // Deploy
        address zkpToken = fac.deploy(salt, code);
        console2.log(chain, "ZKPToken deployed at:", address(zkpToken));

        vm.stopBroadcast();
    }
}
