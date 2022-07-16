// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "base64-sol/base64.sol";

 error Payments__Failed();
 
contract OnDripNFT is ERC721, ERC2981, ERC721URIStorage, ERC721Enumerable {
    using Counters for Counters.Counter;

    bool public s_mintLive;
    uint96 s_royaltyFeeBips;

    address payable public s_contractOwner;
    address s_royaltyReciever; //who gets the royalties its mapped to token id account owners when their token is traded
 
    uint256 public immutable maxInterval = 15768000; //six months
    uint256 public immutable minInterval = 10800; //three hours

    struct cardAttributes {
        address payable accountOwner;
        string description; 
        string imgURI;
        uint256 rateAmount;
        uint256 renewalFee;
        uint256 subscriptionTime;
        bytes32 credentials;
        bool cardValid;
    }
 
    mapping (uint256 => cardAttributes) public s_cardAttributes;

    Counters.Counter private _tokenIdCounter;
 
    constructor(
       
        string memory  _name,
        string memory _symbol,
        address payable _owner,
        uint96 _royaltyFeeBips
 
    ) ERC721(_name,  _symbol) {
        s_contractOwner = _owner;
        s_royaltyFeeBips = _royaltyFeeBips;
    }
 
    //EVENTS 
    event AccountMinted(address indexed _accountOwner, uint _id, string _description, uint _rateAmount, uint __renewalFee, bool _active);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event SubscriptionStatus(address indexed _renter, uint _tokenID, address indexed _receiver, bool _active);
    event SubscriptionUpdate(address indexed _renter, uint _tokenID, uint _hour, address indexed _receiver, uint _amount); //prob can only do time ...
    event FundsWithdrawn(address indexed _from, address indexed _to);

    //MODIFIERS
    modifier getTokeValid(uint256 _tokenID) {
        address renter = ownerOf(_tokenID);
        if(s_cardAttributes[_tokenID].subscriptionTime <= block.timestamp){
            s_cardAttributes[_tokenID].cardValid = false;
        }
        else if(s_cardAttributes[_tokenID].subscriptionTime >= block.timestamp) {
            s_cardAttributes[_tokenID].cardValid = true;
        }

        emit SubscriptionStatus(renter, _tokenID, s_cardAttributes[_tokenID].accountOwner, s_cardAttributes[_tokenID].cardValid);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender==s_contractOwner);
        _;
    }
 
    function mint(

        string memory _vendorURI,
        string memory _description,
        uint256 _rateAmount,
        uint256 _renewalFee, 
        bytes32 _credentials

    ) external {
        
        require(s_mintLive, "Mint isn't live");
 
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
 
        _safeMint(msg.sender, tokenId);

        s_cardAttributes[tokenId] = cardAttributes ({
 
            accountOwner: payable(msg.sender),
            description: _description,
            imgURI: _vendorURI, //IPFS HASH
            rateAmount: _rateAmount, 
            renewalFee: _renewalFee, 
            credentials: _credentials, 
            subscriptionTime: block.timestamp,
            cardValid: false
            });
 
        _setTokenURI(tokenId, tokenURI(tokenId)); 
        emit AccountMinted(msg.sender, tokenId, _description, _rateAmount, _renewalFee, false);  

    }

    function setMint( bool _mintLive) public onlyOwner {
       s_mintLive = _mintLive;
    }

    //NON FUNCTIONAL MIGHT LOOK AT PAYMENT SPLITTER
    function withdrawFunds(uint256 _amount) onlyOwner external payable 
    {
        require(_amount <= address(this).balance, "Contract does not have enough funds to withdraw");
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send");  

        emit FundsWithdrawn(address(this), msg.sender);
    }

    function topUp(uint256 _tokenID) external getTokeValid(_tokenID) payable {
        require(ownerOf(_tokenID) == msg.sender, "not owner");
        require(s_cardAttributes[_tokenID].cardValid == true, "Card not active");

        uint256 newTime = calculateSubscriptionTime(msg.value, _tokenID);

	    if(newTime >= minInterval && newTime <= maxInterval) {

            s_cardAttributes[_tokenID].subscriptionTime += block.timestamp + newTime;
            address receiver = s_cardAttributes[_tokenID].accountOwner; 
            (bool success, ) = receiver.call{value: msg.value}("");
            require(success, "Transfer failed");
	    }
	    else {

            revert Payments__Failed();
        }

    }

    function calculateSubscriptionTime(uint256 _amount, uint256 _tokenID) internal returns (uint256) {
        require(_amount >= s_cardAttributes[_tokenID].rateAmount, "too little payment");
        require(_amount >= s_cardAttributes[_tokenID].rateAmount * 3, "3 hour minimum");

        address currentSub = ownerOf(_tokenID);
        uint256 hour = _amount / s_cardAttributes[_tokenID].rateAmount; 
        uint256 newTime = (hour * 60) * 60;

        emit SubscriptionUpdate(currentSub, _tokenID, hour, s_cardAttributes[_tokenID].accountOwner, _amount);

        return newTime;
       
    }

    function renew(uint256 _tokenID) external payable {
        require(s_cardAttributes[_tokenID].subscriptionTime <= block.timestamp);
        require(ownerOf(_tokenID) == msg.sender, "not owner");
        require(msg.value >= s_cardAttributes[_tokenID].renewalFee);

        address receiver = s_cardAttributes[_tokenID].accountOwner; 
        (bool success, ) = receiver.call{value: msg.value}("");
        require(success, "Transfer failed");
        s_cardAttributes[_tokenID].cardValid = true;
        s_cardAttributes[_tokenID].subscriptionTime += block.timestamp + 10800; 

        emit SubscriptionStatus(msg.sender, _tokenID, s_cardAttributes[_tokenID].accountOwner, s_cardAttributes[_tokenID].cardValid);

    }

    //add token ID so its different accross tokenIDs
    function calculateRoyalty(uint256 _salePrice) view public returns (uint256) {
        return (_salePrice / 10000) * s_royaltyFeeBips;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        
        cardAttributes memory cardAttribute = s_cardAttributes[_tokenId];
        string memory strRateAmount = Strings.toString(cardAttribute.rateAmount);
        string memory imageURI = cardAttribute.imgURI;

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                 '{"name":"',
                                name(),
                                " Description ",
                                '", "description":"',
                                cardAttribute.description,
                                " Vendor",
                                '", "image": "',
                                imageURI,
                                '", "attributes": [{"trait_type":"Rate Amount",',
                                '"value":"',
                                strRateAmount,
                                '"}]}'
                            )
                        )
                    )
                )
            );

    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getTokenCredentials(uint256 _tokenID) external getTokeValid(_tokenID) returns (bytes32) {
        require(ownerOf(_tokenID) == msg.sender, "not owner");
        require(s_cardAttributes[_tokenID].subscriptionTime > block.timestamp);
        require(s_cardAttributes[_tokenID].cardValid == true, "Card not active");
    
        return s_cardAttributes[_tokenID].credentials;
        
    }

    function _burn (uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
 
    }
 
    function balanceOfContract() external view  returns (uint256) {
        return address(this).balance;
    }

 

}