// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AccessControls.sol";

contract ServiceHistory is ERC721("ServiceHistory", "SRV") {
    using SafeMath for uint256;

    struct Entry {
        uint256 mileage;
        uint256 date;
        string garage;
        string description;
    }

    mapping(uint256 => Entry) public serviceBookEntry;

    address public vehicleNftAddress;
    AccessControls public accessControls;

    constructor(AccessControls _accessControls, address _vehicleNftAddress) {
        accessControls = _accessControls;
        vehicleNftAddress = _vehicleNftAddress;
    }

    function mint(uint256 _vehicleNftId) external {
        require(accessControls.isAdmin(_msgSender()), "ServiceHistory.mint: Only admin");

        uint256 tokenId = totalSupply().add(1);

        _safeMint(vehicleNftAddress, tokenId, abi.encodePacked(_vehicleNftId));
    }
}
