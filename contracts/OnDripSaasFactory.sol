// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./OnDripSaas.sol";

contract OnDripSaasFactory {
    uint256 saasCollectionsCounter = 0;

    // Map Id to collection
    mapping(uint256 => OnDripSaas) saasCollections;

    event saaSCollectionCreated(uint256 id, OnDripSaas collection);

    function createSaasCollection(
         string memory _name,
        string memory _symbol,
        address _platformAddress,
        address _vendorAddress,
        address _nftMarketPlace,
        uint96 _royaltyFeeBips
    ) public returns (OnDripSaas) {
        OnDripSaas saasAddress = new OnDripSaas(_name, _symbol, _platformAddress, _vendorAddress, _nftMarketPlace, _royaltyFeeBips);

        saasCollections[saasCollectionsCounter] = saasAddress;
        saasCollectionsCounter++;

        emit saaSCollectionCreated(saasCollectionsCounter, saasAddress);
        return saasAddress;
        
    }

    function getSaasCollection(uint256 id) public view returns (OnDripSaas) {
        return saasCollections[id];
    }

}