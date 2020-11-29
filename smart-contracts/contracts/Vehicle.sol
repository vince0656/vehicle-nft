// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./ERC998/IERC998ERC721TopDown.sol";
import "./ERC998/IERC998ERC721TopDownEnumerable.sol";

contract Vehicle is ERC721, IERC998ERC721TopDown, IERC998ERC721TopDownEnumerable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // return this.rootOwnerOf.selector ^ this.rootOwnerOfChild.selector ^
    //   this.tokenOwnerOf.selector ^ this.ownerOfChild.selector;
    //TODO: this was bytes32.
    bytes4 constant ERC998_MAGIC_VALUE = 0xcd740db5;

    // Set of whitelisted child contracts
    EnumerableSet.AddressSet internal childContracts;

    // Parent token Id => child contract => set of children owned within the child contract
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) internal parentTokenIDToChildrenOwned;

    // Child address => childId => parent tokenId
    mapping(address => mapping(uint256 => uint256)) internal childTokenToParentTokenId;

    mapping(uint256 => string) public tokenIdToVIN;

    constructor(string memory _manufacturer, string memory _symbol) ERC721(_manufacturer, _symbol) {}

    //todo mint needs to take VIN and token uri
    //todo whitelist child contract using access controls contract

    function rootOwnerOf(uint256 _tokenId) external override view returns (address rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    function rootOwnerOfChild(address _childContract, uint256 _childTokenId) public override view returns (address rootOwner) {
        address rootOwnerAddress;

        // When zero passed in, the query is about who owns the Vehicle token ID specified by [_childTokenId] param
        if (_childContract == address(0)) {
            rootOwnerAddress = ownerOf(_childTokenId);
        }

        require(childContracts.contains(_childContract), "Invalid child contract address");
        (rootOwnerAddress,) = _ownerOfChild(_childContract, _childTokenId);

        // Ownership of a child is implicit from the ownership of a vehicle (NFT)
        return rootOwnerAddress;
    }

    function ownerOfChild(address _childContract, uint256 _childTokenId) external override view returns (address parentTokenOwner, uint256 parentTokenId) {
        return _ownerOfChild(_childContract, _childTokenId);
    }

    function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes calldata _data) external override returns (bytes4) {
        return 0x0;
    }

    function transferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external override {

    }

    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external override {

    }

    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId, bytes calldata _data) external override {

    }

    function transferChildToParent(uint256 _fromTokenId, address _toContract, uint256 _toTokenId, address _childContract, uint256 _childTokenId, bytes calldata _data) external override {

    }

    // getChild function enables older contracts like cryptokitties to be transferred into a composable
    // The _childContract must approve this contract. Then getChild can be called.
    function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external override {

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
    // Internal
    // ----------

    function addressToBytes32(address _account) private pure returns (bytes32 result) {
        assembly {
            result := mload(add(_account, 32))
        }
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
