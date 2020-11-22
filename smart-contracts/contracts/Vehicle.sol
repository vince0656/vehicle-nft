// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC998/IERC998ERC721TopDown.sol";
import "./ERC998/IERC998ERC721TopDownEnumerable.sol";

contract Vehicle is ERC721 {
    constructor(string memory _manufacturer, string memory _symbol) ERC721(_manufacturer, _symbol) {}
}
