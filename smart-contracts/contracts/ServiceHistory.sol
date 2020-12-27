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

    /// @notice ServiceHistory token ID -> Entry info
    mapping(uint256 => Entry) public serviceBookEntry;

    AccessControls public accessControls;

    constructor(AccessControls _accessControls) {
        accessControls = _accessControls;
    }

    function mint(
        address _vehicleNftAddress,
        uint256 _vehicleNftId,
        string calldata _uri
    ) external {
        require(accessControls.isAdmin(_msgSender()), "ServiceHistory.mint: Only admin");

        uint256 tokenId = totalSupply().add(1);

        //TODO entry

        _safeMint(_vehicleNftAddress, tokenId, abi.encodePacked(_vehicleNftId));
        _setTokenURI(tokenId, _uri);
    }
}
