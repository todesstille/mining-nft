// SPDX-License-Identifier: MIT
pragma solidity ^1.1.2;

import "spark-std/Script.sol";
import "openzeppelin-contracts-upgradeable/core_openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

import "../src/MiningSoulboundNFT.sol";

contract DeployMiningSoulboundNFTScript is Script {
    function run() external returns (address implementation, address proxy) {
        string memory privateKey = vm.envString("PRIVATE_KEY");
        string memory name_ = vm.envString("MINING_NFT_NAME");
        string memory symbol_ = vm.envString("MINING_NFT_SYMBOL");

        vm.startBroadcast(privateKey);

        MiningSoulboundNFT impl = new MiningSoulboundNFT();
        ERC1967Proxy deployedProxy = new ERC1967Proxy(
            address(impl), abi.encodeWithSelector(MiningSoulboundNFT.initialize.selector, name_, symbol_)
        );

        vm.stopBroadcast();

        implementation = address(impl);
        proxy = address(deployedProxy);

        console2.log("MiningSoulboundNFT implementation:", implementation);
        console2.log("MiningSoulboundNFT proxy:", proxy);
    }
}
