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
/// @notice The top-down composable Vehicle NFT may contain any number of whitelisted NFTs related to events such as ownership change, servicing etc.
/// @author Vincent de Almeida
/// @notice Last Updated 2 Jan 2021
/// @dev Permission to call certain methods is controlled by an external access controls contract
/// @dev This contract only supports wrapping other ERC721 tokens (if the NFT is whitelisted)
contract Vehicle is ERC721, IERC998ERC721TopDown, IERC998ERC721TopDownEnumerable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Events
    event ContractSetup();
    event ChildContractWhitelisted(address indexed contractAddress);

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
    /// @param _tokenName ERC721 token name
    /// @param _tokenSymbol ERC721 token symbol
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
        emit ContractSetup();
    }

    /// @notice Adds an ERC721 contract address to a whitelist that permits wrapping within a vehicle NFT
    /// @dev Only an address with an admin role can whitelist a child NFT
    /// @param _newChildContractAddress Address of the child NFT contract being added to the whitelist
    function whitelistChildContract(address _newChildContractAddress) external {
        require(accessControls.isAdmin(_msgSender()), "Vehicle.whitelistChildContract: Only admin");
        childContracts.add(_newChildContractAddress);
        emit ChildContractWhitelisted(_newChildContractAddress);
    }

    /// @notice Method for tokenizing a vehicle
    /// @dev Only an address with an admin role can mint a vehicle NFT
    /// @param _uri Token URI to more detailed information about a vehicle
    /// @param _VIN Vehicle Identification Number for the vehicle
    /// @param _recipient Address receiving the Vehicle NFT - ideally the vehicle itself
    function mint(string calldata _uri, string calldata _VIN, address _recipient) external {
        require(accessControls.isAdmin(_msgSender()), "Vehicle.mint: Only admin");
        require(_recipient != address(0), "Vehicle.mint: Invalid mint beneficiary");
        require(_recipient != address(this), "Vehicle.mint: Cannot mint to this contract");
        require(!childContracts.contains(_recipient), "Vehicle.mint: Cannot mint to a child contract");
        require(bytes(_uri).length > 0, "Vehicle.mint: URI is empty string");
        require(bytes(_VIN).length > 0, "Vehicle.mint: URI is empty string");

        uint256 tokenId = totalSupply().add(1);

        _safeMint(_recipient, tokenId);
        _setTokenURI(tokenId, _uri);
        tokenIdToVIN[tokenId] = _VIN;
    }

    /// @notice Retrieves the owner of a vehicle NFT
    /// @param _tokenId Token ID of a specific Vehicle NFT
    /// @return rootOwner of the vehicle NFT if it exists
    function rootOwnerOf(uint256 _tokenId) external override view returns (address rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    /// @notice Returns the root owner of a vehicle NFT which contains a specified child
    /// @notice Ownership is transitive. Therefore, owning a vehicle NFT means owning child NFTs
    /// @dev When specifying address zero for the child contract, the method processes this as a query for the owner of the vehicle NFT
    /// @return rootOwner of the child NFT or vehicle NFT if _childContract is the zero address
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

    /// @notice Returns the token ID of the Vehicle NFT that wraps the child NFT and the associated address that owns the vehicle NFT
    /// @param _childContract Address of the child NFT
    /// @param _childTokenId Token ID of the child NFT
    /// @return parentTokenOwner Address that owns the parent Vehicle NFT
    /// @return parentTokenId Token ID of the Vehicle NFT that has the wrapped child NFT
    function ownerOfChild(address _childContract, uint256 _childTokenId) external override view returns (address parentTokenOwner, uint256 parentTokenId) {
        return _ownerOfChild(_childContract, _childTokenId);
    }

    /// @notice Implementation of the function in the ERC721 receiver spec which must be invoked by a whitelisted child contract upon wrapping
    /// @dev Only NFT contracts in the childContracts whitelist can wrap their tokens in a Vehicle NFT
    /// @param _childTokenId ID of the child being wrapped from the sending contract
    /// @param _data Contains the token ID of the Vehicle NFT receiving the new child
    /// @return bytes4 selector of the function to acknowledge the implementation of the receiver interface
    function onERC721Received(address, address _from, uint256 _childTokenId, bytes calldata _data) external override returns (bytes4) {
        require(childContracts.contains(_msgSender()), "Vehicle.onERC721Received: Child contract is not whitelisted");
        require(_data.length == 32, "Vehicle.onERC721Received: _data must contain the uint256 tokenId to transfer the child token to.");

        // Extract the vehicle token ID
        uint256 vehicleTokenId;
        uint256 _index = msg.data.length - 32;
        assembly {vehicleTokenId := calldataload(_index)}

        // Record the linking of the child with the vehicle NFT
        _receiveChild(_from, vehicleTokenId, _msgSender(), _childTokenId);
        require(ERC721(msg.sender).ownerOf(_childTokenId) == address(this), "Child token not owned.");

        // return bytes4 selector of the function to acknowledge the implementation of the receiver interface
        return _ERC721_RECEIVED;
    }

    /// @notice getChild function enables older NFTs (pre ERC-721 ratification) like Cryptokitties to be transferred into a composable
    /// @dev The _childContract must approve this contract. Then getChild can be called.
    /// @param _from Owner of child NFT that has approved this contract
    /// @param _vehicleTokenId Token ID of the vehicle NFT receiving the child
    /// @param _childContract Contract address of the child NFT
    /// @param _childTokenId Token ID of the child NFT
    function getChild(address _from, uint256 _vehicleTokenId, address _childContract, uint256 _childTokenId) external override {
        ERC721 childContract = ERC721(_childContract);
        childContract.transferFrom(_from, address(this), _childTokenId);
        _receiveChild(_from, _vehicleTokenId, _childContract, _childTokenId);
        require(childContract.ownerOf(_childTokenId) == address(this), "Child token not owned.");
    }

    /// @notice Returns how many child contracts have been whitelisted
    /// @return uint256 of the length of the list
    function totalChildContracts() external override view returns (uint256) {
        return childContracts.length();
    }

    /// @notice Get the address of a child contract at a specific index in the whitelist list
    /// @param _index Element index in the whitelist
    /// @return childContract address at the specified index if the index is within bounds
    function childContractByIndex(uint256 _index) external override view returns (address childContract) {
        return childContracts.at(_index);
    }

    /// @notice Given a child NFT contract, this method returns the number of children in that contract that a Vehicle NFT owns
    /// @param _tokenId of the Vehicle NFT
    /// @param _childContract Address of the child NFT
    /// @return uint256 of the number of children
    function totalChildTokens(uint256 _tokenId, address _childContract) external override view returns (uint256) {
        return parentTokenIDToChildrenOwned[_tokenId][_childContract].length();
    }

    /// @notice Gets the token ID of a child token linked to a Vehicle NFT at a specific index
    /// @param _tokenId of the Vehicle NFT
    /// @param _childContract Address of the child NFT
    /// @param _index Index of the element in the list of child tokens of a child NFT owned by a vehicle
    /// @return childTokenId Token ID of the child
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
