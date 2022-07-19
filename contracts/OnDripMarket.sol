// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

//INTERFACE
import "./OnDripNFT.sol";

contract OnDripMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address public payoutAddress;
    uint96 public platformFeeBasisPoint;

    OnDripNFT public onDripNFT;

    address onDripNFTAddress;
     
    constructor(
         address _onDripNFT,
         uint96 _platformFee
     ) {

        onDripNFTAddress = _onDripNFT;
        platformFeeBasisPoint = _platformFee;
        payoutAddress = msg.sender;
     }
     
     struct MarketItem {
         uint itemId;
         address nftContract;
         uint256 tokenId;
         address payable seller;
         address payable owner;
         uint256 price;
         bool sold;
     }
     
     mapping(uint256 => MarketItem) private idToMarketItem;
     
     event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract, //in case we have multiple NFT contracts
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
     );
     
     event MarketItemSold (
         uint indexed itemId,
         uint indexed tokenId,
         address buyer,
         uint256 price 
    );
     
    
    
    function createMarketItem(
        //address nftContract,
        uint256 tokenId,
        uint256 price
        ) public payable nonReentrant {
            require(price > 0, "Price must be greater than 0");
            
            _itemIds.increment();
            uint256 itemId = _itemIds.current();
  
            idToMarketItem[itemId] =  MarketItem(
                itemId,
                onDripNFTAddress,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                price,
                false
            );
            
            IERC721(onDripNFT).transferFrom(msg.sender, address(this), tokenId);
                
            emit MarketItemCreated(
                itemId,
                onDripNFTAddress,
                tokenId,
                msg.sender,
                address(0),
                price,
                false
            );
        }
        
    function createMarketSale(
        //address nftContract,
        uint256 itemId
        ) public payable nonReentrant {
            uint price = idToMarketItem[itemId].price;
            uint tokenId = idToMarketItem[itemId].tokenId;
            bool sold = idToMarketItem[itemId].sold;
            require(msg.value == price, "Please submit the asking price in order to complete the purchase");
            require(sold != true, "This Sale has alredy finnished");

            //Royalty
            (address accountReceiver, uint256 royaltyAmount) = onDripNFT.royaltyInfo(tokenId, price);
  
            uint256 amountReceived = msg.value;
            uint256 amountAfterRoyalty = amountReceived - royaltyAmount;
            uint256 amountToMarketplace = (amountAfterRoyalty * platformFeeBasisPoint) /1000;
            uint256 amountToSeller = amountAfterRoyalty - amountToMarketplace;

            idToMarketItem[itemId].seller.transfer(amountToSeller);
            payable(address(payoutAddress)).transfer(amountToMarketplace);
            payable(address(accountReceiver)).transfer(royaltyAmount);

            IERC721(onDripNFT).transferFrom(address(this), msg.sender, tokenId);

            idToMarketItem[itemId].owner = payable(msg.sender);
            _itemsSold.increment();
            idToMarketItem[itemId].sold = true;
            _itemsSold.increment();
            emit MarketItemSold(itemId, tokenId, msg.sender, price);

        }
    
}