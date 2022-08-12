// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract OnDripMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _auctionIds;
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

    //Auction Events -- may be worth putting owner in her as well for royalty sake
    struct AuctionItem{
         uint itemId;
         address nftContract;
         uint256 tokenId;
         address payable seller;
         address highestBidder;
         address owner;
         uint256 highestBid;
         uint endAt;
         bool started;
         bool ended;
    }
     
    mapping(uint256 => AuctionItem) public idToAuctionItem;
    mapping(address => uint) public bids;
     
     event AuctionItemCreated (
        uint indexed itemId,
        address indexed nftContract, 
        uint256 indexed tokenId,
        string metaDataURI,
        address seller,
        address highestBidder,
        address owner,
        uint256 highestBid,
        uint endAt,
        bool started,
        bool ended
     );

    event Bid(address indexed sender, uint amount);
     
    event AuctionItemSold (
         uint indexed itemId,
         address indexed nftContract, 
         uint indexed tokenId,
         address winner,
         uint highestBid 
    );

    event Withdraw(address indexed bidder, uint amount);

    event Start();

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

    //AUCTION FUNCTIONS
    function createAuctionItem(
        address nftContract, //OPTIONAL IN CASE THERE ARE MULTIPLE SUB ITEMS
        uint256 tokenId,
        uint256 highestBid,
        uint endTime
        ) public onlyItemOwner(nftContract, tokenId) returns (uint256) {
            require(highestBid > 0, "Price must be greater than 0");

            _auctionIds.increment();
            uint256 itemId = _auctionIds.current();

            uint endAt = block.timestamp + endTime;
  
            idToAuctionItem[itemId] =  AuctionItem(
                itemId,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                payable(address(0)),
                highestBid,
                endAt,
                true,
                false
            );
            
            IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
            
            string memory metadataURI = IERC721Metadata(nftContract).tokenURI(tokenId);
                
            emit AuctionItemCreated(
                itemId,
                nftContract,
                tokenId,
                metadataURI,
                msg.sender,
                address(0),
                address(0),
                highestBid,
                endAt,
                true,
                false
            );

            emit Start();

            return itemId;
        }

    //we havea system where we simply the highest bidder for the auction 
    function bid(uint256 _itemId) public payable {
        require(idToAuctionItem[_itemId].started, "not started");
        require(block.timestamp < idToAuctionItem[_itemId].endAt, "ended");
        require(msg.value > idToAuctionItem[_itemId].highestBid, "value < highest");

        if (idToAuctionItem[_itemId].highestBidder != address(0)) {
            bids[idToAuctionItem[_itemId].highestBidder] += idToAuctionItem[_itemId].highestBid;
        }

        idToAuctionItem[_itemId].highestBidder = msg.sender;
        idToAuctionItem[_itemId].highestBid = msg.value;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() public {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
    }

    function end(uint256 _itemId) public {
        require(idToAuctionItem[_itemId].started, "not started");
        require(block.timestamp >= idToAuctionItem[_itemId].endAt, "not ended");
        require(!idToAuctionItem[_itemId].ended, "ended");

        idToAuctionItem[_itemId].ended = true;
        if (idToAuctionItem[_itemId].highestBidder != address(0)) {

            (address accountReceiver, uint256 royaltyAmount) = IERC2981(idToAuctionItem[_itemId].nftContract).royaltyInfo(idToAuctionItem[_itemId].tokenId, idToAuctionItem[_itemId].highestBid);
            uint256 amountReceived = idToAuctionItem[_itemId].highestBid;
            uint256 amountAfterRoyalty = amountReceived - royaltyAmount;
            uint256 amountToMarketplace = (amountAfterRoyalty * platformFeeBasisPoint) /1000;
            uint256 amountToSeller = amountAfterRoyalty - amountToMarketplace;

            IERC721(idToAuctionItem[_itemId].nftContract).transferFrom(address(this), idToAuctionItem[_itemId].highestBidder, idToAuctionItem[_itemId].tokenId);

            idToAuctionItem[_itemId].seller.transfer(amountToSeller);
            payable(address(owner)).transfer(amountToMarketplace);
            payable(address(accountReceiver)).transfer(royaltyAmount);
           

        } else {

            IERC721(idToAuctionItem[_itemId].nftContract).transferFrom(address(this), idToAuctionItem[_itemId].seller, idToAuctionItem[_itemId].tokenId);
        }
        emit AuctionItemSold (
            _itemId,
            idToAuctionItem[_itemId].nftContract, 
            idToAuctionItem[_itemId].tokenId,
            idToAuctionItem[_itemId].highestBidder,
            idToAuctionItem[_itemId].highestBid
        );
    }
}