// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Factory {
    function deploy(
        bytes32 salt,
        bytes memory code
    ) external returns (address) {
        require(code.length > 0, "Code cannot be empty");
        require(salt != bytes32(0), "Salt cannot be zero");

        address addr;

        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
        }

        require(addr != address(0), "Deployment failed");

        return addr;
    }
}
