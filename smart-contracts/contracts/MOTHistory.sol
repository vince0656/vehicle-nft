// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AccessControls.sol";

contract MOTHistory is ERC721("MOTHistory", "MOT") {
    using SafeMath for uint256;

    struct MOT {
        uint256 mileage;
        uint256 date;
        address garage;
        bool pass;
        string advisories;
    }

    /// @notice MOTHistory token ID -> MOT info
    mapping(uint256 => MOT) public motEntry;

    AccessControls public accessControls;

    constructor(AccessControls _accessControls) {
        accessControls = _accessControls;
    }

    function mint(
        address _vehicleNftAddress,
        uint256 _vehicleNftId,
        string calldata _uri,
        uint256 _mileage,
        bool _pass,
        string calldata _advisories
    ) external {
        require(accessControls.isGarage(_msgSender()), "MOTHistory.mint: Only authorised garage");

        uint256 tokenId = totalSupply().add(1);

        motEntry[tokenId] = MOT({
            mileage: _mileage,
            date: block.timestamp,
            garage: _msgSender(),
            pass: _pass,
            advisories: _advisories
        });

        _safeMint(_vehicleNftAddress, tokenId, abi.encodePacked(_vehicleNftId));
        _setTokenURI(tokenId, _uri);
    }

    function getEntry(uint256 _tokenId) external view returns (MOT memory) {
        return motEntry[_tokenId];
    }
}
