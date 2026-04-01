// SPDX-License-Identifier: MIT
pragma solidity ^1.1.2;

import "spark-std/Script.sol";

import "../src/MiningSoulboundNFT.sol";

contract DeployMiningSoulboundLogicOnlyScript is Script {
    function run() external returns (address implementation) {
        string memory privateKey = vm.envString("PRIVATE_KEY");

        vm.startBroadcast(privateKey);
        MiningSoulboundNFT impl = new MiningSoulboundNFT();
        vm.stopBroadcast();

        implementation = address(impl);
        console2.log("MiningSoulboundNFT implementation:", implementation);
    }
}
