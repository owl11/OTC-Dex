// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract mockToken is ERC20, ERC20Permit {
    constructor(address _owner) ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        super._mint(_owner, 10000 ether);
    }
}
