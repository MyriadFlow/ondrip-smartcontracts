// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./OnDripDL.sol";

contract OnDripFactory {

    uint256 dlCollectionsCounter = 0;

    // Map Id to collection
    mapping(uint256 => OnDripDL) dlCollections;

    event dlCollectionCreated(uint256 id, OnDripDL collection);

    function createDLCollection(
        string memory _name,
        string memory _symbol,
        address _platformAddress,
        address _vendorAddress,
        address _nftMarketPlace,
        uint96 _royaltyFeeBips
    ) public returns (OnDripDL) {
        OnDripDL dlAddress = new OnDripDL(_name, _symbol, _platformAddress, _vendorAddress, _nftMarketPlace, _royaltyFeeBips);

        dlCollections[dlCollectionsCounter] = dlAddress;
        dlCollectionsCounter++;

        emit dlCollectionCreated(dlCollectionsCounter, dlAddress);
        return dlAddress;
        
    }

    function getDLCollection(uint256 id) public view returns (OnDripDL) {
        return dlCollections[id];
    }

}