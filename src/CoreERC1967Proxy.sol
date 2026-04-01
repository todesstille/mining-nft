// SPDX-License-Identifier: MIT
pragma solidity ^1.1.2;

import "openzeppelin-contracts-upgradeable/core_openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract CoreERC1967Proxy is ERC1967Proxy {
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) {}
}
