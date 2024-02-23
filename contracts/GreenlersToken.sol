// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract Greenlers is ERC20 {
    constructor() ERC20("Greenlers", "GRN") {
        _mint(msg.sender, 100000000000000000000000000);
    }
}