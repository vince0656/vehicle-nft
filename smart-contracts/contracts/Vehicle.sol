// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Vehicle is ERC721("Vehicle", "VCL") {
    constructor() {}
}
