// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AccessControls.sol";

/// @title ERC721 NFT contract for tokenizing MOT events and wrapping that in a vehicle
/// @author Vincent de Almeida
/// @notice Last Updated 2 Jan 2021
contract MOTHistory is ERC721("MOTHistory", "MOT") {
    using SafeMath for uint256;

    // Core MOT data
    struct MOT {
        uint256 mileage;
        uint256 date;
        address garage;
        bool pass;
        string advisories;
    }

    /// @notice MOTHistory token ID -> MOT info
    mapping(uint256 => MOT) public mot;

    /// @notice Address of the access control contract
    AccessControls public accessControls;

    /// @param _accessControls Address of the access control contract
    constructor(AccessControls _accessControls) {
        accessControls = _accessControls;
    }

    /// @notice Method for tokenizing an MOT and instantly wrapping within a vehicle NFT
    /// @dev Only an address with the garage role (authorised service partner) can invoke this method
    /// @param _vehicleNftAddress Address of the vehicle NFT contract
    /// @param _vehicleNftId Vehicle token ID receiving the MOT NFT
    /// @param _uri Token URI for any additional token metadata
    /// @param _mileage of the vehicle at the time of MOT
    /// @param _pass whether the MOT passed or failed
    /// @param _advisories Information on advisories if any
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

        mot[tokenId] = MOT({
            mileage: _mileage,
            date: block.timestamp,
            garage: _msgSender(),
            pass: _pass,
            advisories: _advisories
        });

        _safeMint(_vehicleNftAddress, tokenId, abi.encodePacked(_vehicleNftId));
        _setTokenURI(tokenId, _uri);
    }

    /// @notice Query for MOT information from a token ID
    /// @param _tokenId of the MOT token
    /// @return MOT struct data
    function getMOTByTokenId(uint256 _tokenId) external view returns (MOT memory) {
        return mot[_tokenId];
    }
}
