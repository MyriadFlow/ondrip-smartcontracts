// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract OnDripMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    uint96 public platformFeeBasisPoint;
    address public owner;
     
    constructor(
   
         address _owner,
         uint96 _platformFee
         
     ) {

        platformFeeBasisPoint = _platformFee;
        owner = _owner;
     }
     
     struct MarketItem {
         uint itemId;
         address nftContract;
         uint256 tokenId;
         address payable seller;
         address payable owner;
         uint256 price;
         bool forSale;
         bool deleted;
     }
     
     mapping(uint256 => MarketItem) public idToMarketItem;
     
     event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract, 
        uint256 indexed tokenId,
        string metaDataURI,
        address seller,
        address owner,
        uint256 price,
        bool forSale
     );
     
    event MarketItemSold (
         uint indexed itemId,
         uint indexed tokenId,
         address buyer,
         uint256 price 
    );

    event MarketItemRemoved(uint256 itemId);

    //Modifers 

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWhenItemIsForSale(uint256 itemId){
        require(
            idToMarketItem[itemId].forSale == true,
            "Marketplace: Market item is not for sale"
        );
        _;
    }

    modifier onlyItemOwner(address nftContract, uint256 tokenId) {
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Marketplace: Sender does not own the item"
        );
        _;
    }

    modifier onlySeller(uint256 itemId) {
        require(
            idToMarketItem[itemId].seller == msg.sender,
            "Marketplace: Sender is not seller of this item"
        );
        _;
    } 

    function createMarketItem(
        address nftContract, //OPTIONAL IN CASE THERE ARE MULTIPLE SUB ITEMS
        uint256 tokenId,
        uint256 price
        ) public onlyItemOwner(nftContract, tokenId) returns (uint256) {
            require(price > 0, "Price must be greater than 0");

            _itemIds.increment();
            uint256 itemId = _itemIds.current();
  
            idToMarketItem[itemId] =  MarketItem(
                itemId,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                price,
                true,
                false
            );
            
            
            IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
            
            string memory metadataURI = IERC721Metadata(nftContract).tokenURI(tokenId);
                
            emit MarketItemCreated(
                itemId,
                nftContract,
                tokenId,
                metadataURI,
                msg.sender,
                address(0),
                price,
                false
            );

            return itemId;
        }

    function removeFromSale(uint256 itemId) public onlySeller(itemId) {
        IERC721(idToMarketItem[itemId].nftContract).transferFrom(
            address(this),
            idToMarketItem[itemId].seller,
            idToMarketItem[itemId].tokenId
        );
        idToMarketItem[itemId].deleted = true;

        emit MarketItemRemoved(itemId);
        delete idToMarketItem[itemId];
    }

    function createMarketSale(
        uint256 itemId
        ) public payable nonReentrant onlyWhenItemIsForSale(itemId) {
            uint price = idToMarketItem[itemId].price;
            uint tokenId = idToMarketItem[itemId].tokenId;
            require(msg.value >= price, "Please submit the asking price in order to complete the purchase");

            //Royalty
            (address accountReceiver, uint256 royaltyAmount) = IERC2981(idToMarketItem[itemId].nftContract).royaltyInfo(tokenId, price);
  
            uint256 amountReceived = msg.value;
            uint256 amountAfterRoyalty = amountReceived - royaltyAmount;
            uint256 amountToMarketplace = (amountAfterRoyalty * platformFeeBasisPoint) /1000;
            uint256 amountToSeller = amountAfterRoyalty - amountToMarketplace;

            idToMarketItem[itemId].seller.transfer(amountToSeller);
            payable(address(owner)).transfer(amountToMarketplace);
            payable(address(accountReceiver)).transfer(royaltyAmount);

            IERC721(idToMarketItem[itemId].nftContract).transferFrom(address(this), msg.sender, tokenId);

            idToMarketItem[itemId].owner = payable(msg.sender);
            _itemsSold.increment();
            idToMarketItem[itemId].forSale = false;
            _itemsSold.increment();
            emit MarketItemSold(itemId, tokenId, msg.sender, price);

        }
    
}