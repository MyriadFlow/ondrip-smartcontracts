// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "base64-sol/base64.sol";

 error Payments__Failed();

 //UNFINISHED CONTRACT NEEDS LOTS MORE TESTING 
 //TO DO 
 //OPTIMIZE FOR GAS
 //ADD URI/METADATA, ADD RENEW FUNCTION, ADD EXTRA WITHDRAW FUNCTIONS (BALANCE SETTLEMENT ETC), TEST THE RATE FUNCTION, ADD TOKEN VALIDITY
 
contract OnDripNFT is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;

    uint public s_mintPrice; //in case there is a fee on intitial mint
    bool public s_mintLive;

    //IMAGES WILL ALSO NEED JSON FOR TRAITS ON OPENSEA
    string private s_netflixIMGURI;
    string private s_spotifyIMGURI;

    address payable public s_contractOwner;
 
    uint256 public immutable maxInterval = 15768000; //six months
    uint256 public immutable minInterval = 10800; //three hours

    enum CardValid {
        Active,
        Inactive
    }

    struct cardAttributes {
        address payable accountOwner;
        string vendor;
        string description; //this will be metadata
        string imgURI; //possibly status icon
        uint256 rateAmount;
        uint256 renewalFee;
        uint256 subscriptionTime;
        bytes32 credentials;
        CardValid cardValid;
    }
 
    //DAO card mapped to a token ID
    mapping (uint256 => cardAttributes) private s_cardAttributes;

    Counters.Counter private _tokenIdCounter;
 
    constructor(
       
        string memory  _name,
        string memory _symbol,
        string memory _spotIMG,
        string memory _netIMG,
        address payable _owner
 
    ) ERC721(_name,  _symbol) {
        s_contractOwner = _owner;
        s_netflixIMGURI = svgToImageURI(_spotIMG);
        s_spotifyIMGURI = svgToImageURI(_netIMG);

    }
 
    //ADD MORE EVENTS 
    event Mint(address _from, uint _id);
    event OwnershipTransferred(address _from, address _to);
    event Subscriptions(address _from, address _to);
    event FundsWithdrawn(address _from, address _to);

    //Modifiers
    modifier getTokeValid(uint256 _tokenID) {
        if(s_cardAttributes[_tokenID].subscriptionTime <= block.timestamp){
            s_cardAttributes[_tokenID].cardValid == CardValid.Inactive;
        }
        else {
            s_cardAttributes[_tokenID].cardValid == CardValid.Active;
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender==s_contractOwner);
        _;
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
 
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }
 
    function mint(

        string memory _vendor,
        string memory _description,
        uint256 _rateAmount,
        uint256 _renewalFee, 
        bytes32 _credentials

    ) external payable {
        
        //MIGHT NOT NEED THIS OR PAYABLE
        require(msg.value >= s_mintPrice, "insufficient funds");
        require(s_mintLive, "Mint isn't live");
 
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
 
        _safeMint(msg.sender, tokenId);
        string memory URIVender;

            s_cardAttributes[tokenId] = cardAttributes ({
 
                accountOwner: payable(msg.sender),
                vendor: _vendor,
                description: _description,
                rateAmount: _rateAmount, 
                renewalFee: _renewalFee, 
                credentials: _credentials, 
                imgURI: URIVender,
                subscriptionTime: block.timestamp,
                cardValid: CardValid.Inactive
            });
 
        _setTokenURI(tokenId, tokenURI(tokenId));
        emit Mint(msg.sender, tokenId); //possibly elaborate on this function more include more of card traits   

    }

    function setMint( uint256 _amount, bool _mintLive) external onlyOwner {
       s_mintPrice = _amount;
       s_mintLive = _mintLive;
    }

    function withdrawFunds(uint256 _amount) onlyOwner external payable 
    {
        require(_amount <= address(this).balance, "Contract does not have enough funds to withdraw");
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send");     
   
    }

    function topUp(uint256 _tokenID) external getTokeValid(_tokenID) payable {
        require(ownerOf(_tokenID) == msg.sender, "not owner");
        require(s_cardAttributes[_tokenID].cardValid == CardValid.Active, "Card not active");

        uint256 newTime =  calculateSubscriptionTime(msg.value, _tokenID);
	    if(newTime > minInterval && newTime < maxInterval) {

            s_cardAttributes[_tokenID].subscriptionTime += block.timestamp + newTime;
            address receiver = s_cardAttributes[_tokenID].accountOwner; 
            (bool success, ) = receiver.call{value: msg.value}("");
            require(success, "Transfer failed");
	    }
	    else {

            revert Payments__Failed();
        }
        
    }

    function calculateSubscriptionTime(uint256 _amount, uint256 _tokenID) internal view returns (uint256) {
        require(_amount >= s_cardAttributes[_tokenID].rateAmount, "too little payment");
        require(_amount == s_cardAttributes[_tokenID].rateAmount * 3, "3 hour minimum");

        uint256 hour = _amount / s_cardAttributes[_tokenID].rateAmount; 
        uint256 newTime = (hour * 60) * 60;
        return newTime;
       
    }

    function renew(uint256 _tokenID) external payable {
        require(s_cardAttributes[_tokenID].subscriptionTime <= block.timestamp);
        require(ownerOf(_tokenID) == msg.sender, "not owner");
        require(msg.value >= s_cardAttributes[_tokenID].renewalFee);

        address receiver = s_cardAttributes[_tokenID].accountOwner; 
        (bool success, ) = receiver.call{value: msg.value}("");
        require(success, "Transfer failed");

        s_cardAttributes[_tokenID].cardValid = CardValid.Active;

    }

    //On Chain Token URI - switch to IPFS Or FILE COIN
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        
    }

    function getTokenCredentials(uint256 _tokenID) external getTokeValid(_tokenID) view returns (bytes32) {
        require(ownerOf(_tokenID) == msg.sender, "not owner");
        require(s_cardAttributes[_tokenID].subscriptionTime > block.timestamp);

        return s_cardAttributes[_tokenID].credentials;
        
    }

    function getTotalSupply() external view returns (uint256) {
        uint256 supply = _tokenIdCounter.current();
        return supply;
    }
 
    function _burn (uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
 
    }
 
    //Not sure if this is actually needed
     function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
       
        super._beforeTokenTransfer(from, to, tokenId);
    }
 
    //TESTING
    function balanceOfContract() external view  returns (uint256) {
        return address(this).balance;
    }
 
    //TESTING
    function getcurrentTimeStamp() external view returns (uint256) {
        return block.timestamp;
    }

    //TESTING - get tokenUri function 
    function getTokenUri(uint256 _tokenId) external view returns (string memory){
        string memory _tokenURI = tokenURI(_tokenId);
        return _tokenURI;
    }

}
 
 ////////////////////////////////////////////////////EXTRA FUNCTIONS/////////////////////////////////////////////////

    //with only one minting contract we this will be hard to do without a mapping, or changing state a bunch of times -- we will come back to this
    //function withdrawSettlmentFunds(uint256 _tokenId) public
    //{
        //require(s_cardAttributes[_tokenId].accountOwner == msg.sender, "you are not the account owner" ); 
   
    //}


    
    //Possible kill switch if needed
    //function killSwitch(uint256 _tokenId) external
    //{
        //require(s_cardAttributes[_tokenId].accountOwner == msg.sender, "you are not the account owner" ); 
        //require(s_cardAttributes[_tokenId].cardState == CardValid.NONVALID, "card is still in use");
   
            //_burn(_tokenId);
            //delete s_cardAttributes[_tokenId];
    //}
 
 
