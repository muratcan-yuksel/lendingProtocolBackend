// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//This contract will be deployed after lendingprotocol.sol//

contract LPToken is ERC20, Ownable {
    // address public lendingProtocol; // Address of the lending protocol contract

    constructor() ERC20("LPToken", "LPT") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** 18);
        // _mint(lendingProtocol, 250000 * 10 ** 18);
    }
}
