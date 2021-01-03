// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ERC998/IERC998ERC721TopDown.sol";
import "./ERC998/IERC998ERC721TopDownEnumerable.sol";
import "./AccessControls.sol";

/// @title ERC721 and ERC998 Compatible contract for tokenizing a vehicle based on a specific make and model
/// @author Vincent de Almeida
/// @notice Last Updated 2 Jan 2021
/// @dev Permission to call certain methods is controlled by an external access controls contract
/// @dev This contract only supports wrapping other ERC721 tokens (if the NFT is whitelisted)
contract Vehicle is ERC721, IERC998ERC721TopDown, IERC998ERC721TopDownEnumerable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Equals `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Set of whitelisted child contracts i.e. ServiceHistory, MOTs, Owners
    EnumerableSet.AddressSet internal childContracts;

    // Vehicle token ID => child contract => set of children owned within the child contract
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) internal parentTokenIDToChildrenOwned;

    // Child contract address => child token ID => Vehicle token ID
    mapping(address => mapping(uint256 => uint256)) internal childTokenToParentTokenId;

    /// @notice Function for retrieving a vehicle identification number from a token ID
    mapping(uint256 => string) public tokenIdToVIN;

    /// @notice Address of the access controls contract
    AccessControls public accessControls;

    /// @notice Vehicle manufacturer
    string public manufacturer;

    /// @notice Vehicle model
    string public model;

    /// @param _manufacturer Vehicle Manufacturer
    /// @param _model Vehicle model
    /// @param _tokenName ERC721 name
    /// @param _tokenSymbol ERC721 symbol
    /// @param _accessControls Address of the access control contract
    constructor(
        string memory _manufacturer,
        string memory _model,
        string memory _tokenName,
        string memory _tokenSymbol,
        AccessControls _accessControls
    ) ERC721(_tokenName, _tokenSymbol) {
        manufacturer = _manufacturer;
        model = _model;
        accessControls = _accessControls;
    }

    function whitelistChildContract(address _newChildContractAddress) external {
        require(accessControls.isAdmin(_msgSender()), "Vehicle.whitelistChildContract: Only admin");
        childContracts.add(_newChildContractAddress);
    }

    function mint(string calldata _uri, string calldata _VIN, address _beneficiary) external {
        require(accessControls.isAdmin(_msgSender()), "Vehicle.mint: Only admin");
        require(_beneficiary != address(0), "Vehicle.mint: Invalid mint beneficiary");
        require(_beneficiary != address(this), "Vehicle.mint: Cannot mint to this contract");
        require(!childContracts.contains(_beneficiary), "Vehicle.mint: Cannot mint to a child contract");
        require(bytes(_uri).length > 0, "Vehicle.mint: URI is empty string");
        require(bytes(_VIN).length > 0, "Vehicle.mint: URI is empty string");

        uint256 tokenId = totalSupply().add(1);

        _safeMint(_beneficiary, tokenId);
        _setTokenURI(tokenId, _uri);
        tokenIdToVIN[tokenId] = _VIN;
    }

    function rootOwnerOf(uint256 _tokenId) external override view returns (address rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    function rootOwnerOfChild(address _childContract, uint256 _childTokenId) public override view returns (address rootOwner) {
        // When zero passed in, the query is about who owns the Vehicle token ID specified by [_childTokenId] param
        if (_childContract == address(0)) {
            return ownerOf(_childTokenId);
        }

        require(childContracts.contains(_childContract), "Invalid child contract address");
        (address rootOwnerAddress,) = _ownerOfChild(_childContract, _childTokenId);

        // Ownership of a child is implicit from the ownership of a vehicle (NFT)
        return rootOwnerAddress;
    }

    function ownerOfChild(address _childContract, uint256 _childTokenId) external override view returns (address parentTokenOwner, uint256 parentTokenId) {
        return _ownerOfChild(_childContract, _childTokenId);
    }

    function onERC721Received(address, address _from, uint256 _childTokenId, bytes calldata _data) external override returns (bytes4) {
        require(childContracts.contains(_msgSender()), "Vehicle.onERC721Received: Child contract is not whitelisted");
        require(_data.length == 32, "Vehicle.onERC721Received: _data must contain the uint256 tokenId to transfer the child token to.");

        uint256 tokenId;
        uint256 _index = msg.data.length - 32;
        assembly {tokenId := calldataload(_index)}

        _receiveChild(_from, tokenId, _msgSender(), _childTokenId);
        require(ERC721(msg.sender).ownerOf(_childTokenId) == address(this), "Child token not owned.");

        return _ERC721_RECEIVED;
    }

    // getChild function enables older contracts like cryptokitties to be transferred into a composable
    // The _childContract must approve this contract. Then getChild can be called.
    function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external override {
        //TODO
    }

    // enumerable interface
    function totalChildContracts() external override view returns (uint256) {
        return childContracts.length();
    }

    function childContractByIndex(uint256 _index) external override view returns (address childContract) {
        return childContracts.at(_index);
    }

    function totalChildTokens(uint256 _tokenId, address _childContract) external override view returns (uint256) {
        return parentTokenIDToChildrenOwned[_tokenId][_childContract].length();
    }

    function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external override view returns (uint256 childTokenId) {
        return parentTokenIDToChildrenOwned[_tokenId][_childContract].at(_index);
    }

    // ----------
    // Private
    // ----------

    function _receiveChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) private {
        require(ownerOf(_tokenId) != address(0));
        require(
            !parentTokenIDToChildrenOwned[_tokenId][_childContract].contains(_childTokenId),
            "Cannot receive child token because it has already been received."
        );

        parentTokenIDToChildrenOwned[_tokenId][_childContract].add(_childTokenId);
        childTokenToParentTokenId[_childContract][_childTokenId] = _tokenId;

        emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
    }

    function _ownerOfChild(address _childContract, uint256 _childTokenId) internal view returns (address parentTokenOwner, uint256 parentTokenId) {
        parentTokenId = childTokenToParentTokenId[_childContract][_childTokenId];

        require(
            parentTokenId > 0 || parentTokenIDToChildrenOwned[parentTokenId][_childContract].contains(_childTokenId),
            "Vehicle._ownerOfChild: Child does not belong to any parent"
        );

        return (ownerOf(parentTokenId), parentTokenId);
    }
}
