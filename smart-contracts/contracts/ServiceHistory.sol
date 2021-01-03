// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AccessControls.sol";

/// @title ERC721 NFT contract for tokenizing Servicing events and wrapping that in a vehicle
/// @author Vincent de Almeida
/// @notice Last Updated 2 Jan 2021
contract ServiceHistory is ERC721("ServiceHistory", "SRV") {
    using SafeMath for uint256;

    // Service book entry data
    struct Entry {
        uint256 mileage;
        uint256 date;
        address garage;
        string description;
    }

    /// @notice ServiceHistory token ID -> Entry info
    mapping(uint256 => Entry) public serviceBookEntry;

    /// @notice Address of the access control contract
    AccessControls public accessControls;

    /// @param _accessControls Address of the access control contract
    constructor(AccessControls _accessControls) {
        accessControls = _accessControls;
    }
    /// @notice Method for tokenizing a service book entry and instantly wrapping within a vehicle NFT
    /// @dev Only an address with the garage role (authorised service partner) can invoke this method
    /// @param _vehicleNftAddress Address of the vehicle NFT contract
    /// @param _vehicleNftId Vehicle token ID receiving the ServiceHistory NFT
    /// @param _uri Token URI for any additional token metadata
    /// @param _mileage of the vehicle at the time of the service
    /// @param _description Details if any about the service
    function mint(
        address _vehicleNftAddress,
        uint256 _vehicleNftId,
        string calldata _uri,
        uint256 _mileage,
        string calldata _description
    ) external {
        require(accessControls.isGarage(_msgSender()), "ServiceHistory.mint: Only authorised garage");

        uint256 tokenId = totalSupply().add(1);

        serviceBookEntry[tokenId] = Entry({
            mileage: _mileage,
            date: block.timestamp,
            garage: _msgSender(),
            description: _description
        });

        _safeMint(_vehicleNftAddress, tokenId, abi.encodePacked(_vehicleNftId));
        _setTokenURI(tokenId, _uri);
    }

    /// @notice Get service book entry for a given token ID
    /// @param _tokenId of the ServiceHistory token
    /// @return Entry struct data
    function getServiceBookEntryForTokenId(uint256 _tokenId) external view returns (Entry memory) {
        return serviceBookEntry[_tokenId];
    }
}
