// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC998/IERC998ERC721TopDown.sol";
import "./ERC998/IERC998ERC721TopDownEnumerable.sol";

contract Vehicle is ERC721, IERC998ERC721TopDown, IERC998ERC721TopDownEnumerable {
    // return this.rootOwnerOf.selector ^ this.rootOwnerOfChild.selector ^
    //   this.tokenOwnerOf.selector ^ this.ownerOfChild.selector;
    bytes32 constant ERC998_MAGIC_VALUE = 0xcd740db5;

    // child address => childId => tokenId
    mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;

    constructor(string memory _manufacturer, string memory _symbol) ERC721(_manufacturer, _symbol) {}

//    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
//        bytes memory tempEmptyStringTest = bytes(source);
//        if (tempEmptyStringTest.length == 0) {
//            return 0x0;
//        }
//
//        assembly {
//            result := mload(add(source, 32))
//        }
//    }

    function rootOwnerOf(uint256 _tokenId) external override view returns (bytes32 rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    function rootOwnerOfChild(address _childContract, uint256 _childTokenId) public override view returns (bytes32 rootOwner) {
        address rootOwnerAddress;

        // When zero passed in, the query is about who owns the Vehicle token ID specified by [_childTokenId] param
        if (_childContract == address(0)) {
            rootOwnerAddress = ownerOf(_childTokenId);
        }

        (rootOwnerAddress,) = _ownerOfChild(_childContract, _childTokenId);

        // todo, check that the child is whitelisted
        // todo, check that the child is linked to a parent

        // Ownership of a child is implicit from the ownership of a vehicle (NFT)
        return ERC998_MAGIC_VALUE << 224 | bytes32(rootOwnerAddress);
    }

    function ownerOfChild(address _childContract, uint256 _childTokenId) external override view returns (bytes32 parentTokenOwner, uint256 parentTokenId) {
        return (0x0, 0);
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
    function totalChildContracts(uint256 _tokenId) external view returns (uint256) {
        return 0;
    }

    function childContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address childContract) {
        return address(0);
    }

    function totalChildTokens(uint256 _tokenId, address _childContract) external view returns (uint256) {
        return 0;
    }

    function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external view returns (uint256 childTokenId) {
        return 0;
    }

    function _ownerOfChild(address _childContract, uint256 _childTokenId) internal view returns (address parentTokenOwner, uint256 parentTokenId) {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId > 0 || childTokenIndex[parentTokenId][_childContract][_childTokenId] > 0);
        return (tokenIdToTokenOwner[parentTokenId], parentTokenId);
    }
}
