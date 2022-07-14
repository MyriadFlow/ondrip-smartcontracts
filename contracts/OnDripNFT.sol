// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

 error Payments__Failed();

 //UNFINISHED CONTRACT NEEDS LOTS MORE TESTING 
 //TO DO 
 //OPTIMIZE FOR GAS
 //ADD URI/METADATA, ADD RENEW FUNCTION, ADD EXTRA WITHDRAW FUNCTIONS (BALANCE SETTLEMENT ETC), TEST THE RATE FUNCTION, ADD TOKEN VALIDITY
 
contract OnDripNFT is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;

    uint public s_mintPrice; //in case there is a fee on intitial mint
    bool public s_mintLive;

    address payable public s_contractOwner;
 

    uint256 public immutable maxInterval = 15768000; //six months
    uint256 public immutable minInterval = 10800; //three hours
 
    enum CardValid {
        VALID,
        NONVALID
    }

    struct cardAttributes {
        address payable accountOwner;
        string vendor;
        string description; //this will be metadata
        string imgURI; //possibly status icon
        uint256 rateAmount;
        uint256 salePrice;
        uint256 subscriptionTime;
        bytes32 credentials;
        CardValid cardState;
    }
 
    //DAO card mapped to a token ID
    mapping (uint256 => cardAttributes) private s_cardAttributes;

    //On Chain URI?
    string[] subscriptionStatus = [
        "In Use",
        "Not In Use"
    ];

    //grab the img URI for these two things 
    string[] tokenIMGURI = [
        "Netflix",
        "Spotify"
    ];

    Counters.Counter private _tokenIdCounter;
 
    constructor(
       
        string memory  _name,
        string memory _symbol,
        address payable _owner
 
    ) ERC721(_name,  _symbol) {
        s_contractOwner = _owner;
    }
 
    //ADD MORE EVENTS 
    event Mint(address _from, uint _id);
    event OwnershipTransferred(address _from, address _to);

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender==s_contractOwner);
        _;
    }
 
   //we may need another function to ! GET the hashed NFT credentials unsure
    function mint(

        string memory _vender,
        string memory _description,
        uint256 _rateAmount,
        uint256 _floorPrice,
        bytes32 _credentials

    ) external payable {
        
        require(msg.value >= s_mintPrice, "insufficient funds");
        require(s_mintLive, "Mint isn't live");
 
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
 
        _safeMint(msg.sender, tokenId);
        string memory URIMemberStatus = string(abi.encodePacked(subscriptionStatus[0]));
       
            s_cardAttributes[tokenId] = cardAttributes ({
 
                //we may need blocktime in this struct
                accountOwner: payable(msg.sender),
                vendor: _vender,
                description: _description,
                rateAmount: _rateAmount, //pre set rate amount
                salePrice: _floorPrice, //this may not be needed as people could just just choose what they want to sell it for
                credentials: _credentials, 
                imgURI: URIMemberStatus,
                subscriptionTime: block.timestamp,
                cardState: CardValid.NONVALID
            });
 
        _setTokenURI(tokenId, tokenURI(tokenId));
        emit Mint(msg.sender, tokenId); //possibly elaborate on this function more include more of card traits   

    }

    function setMint( uint256 _amount, bool _mintLive) public onlyOwner {
       s_mintPrice = _amount;
       s_mintLive = _mintLive;
    }

    //function withdrawSettlmentFunds(uint256 _tokenId) -- withdrawSettlmentFunds RETURN BACK TO

    //Possible kill switch if needed
    //function killSwitch(uint256 _tokenId) external
    //{
        //require(s_cardAttributes[_tokenId].accountOwner == msg.sender, "you are not the account owner" ); 
        //require(s_cardAttributes[_tokenId].cardState == CardValid.NONVALID, "card is still in use");
   
            //_burn(_tokenId);
            //delete s_cardAttributes[_tokenId];
    //}

    function withdrawFunds(uint256 _amount) onlyOwner external payable 
    {
        require(_amount <= address(this).balance, "Contract does not have enough funds to withdraw");
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send");     
   
    }

    function topUp(uint256 _tokenID) external payable {
        require(ownerOf(_tokenID) == msg.sender, "not owner");

        uint256 newTime =  calculateSubscriptionTime(msg.value, _tokenID); //this could be a modifer
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

    //NEED TO RE-VISIT AND IMPROVE
    function calculateSubscriptionTime(uint256 _amount, uint256 _tokenID) internal view returns (uint256) {
        require(_amount >= s_cardAttributes[_tokenID].rateAmount, "too little");
        require(_amount == s_cardAttributes[_tokenID].rateAmount * 3, "3 hour minimum");

        uint256 hour = _amount / s_cardAttributes[_tokenID].rateAmount; 
        uint256 newTime = (hour * 60) * 60;
        return newTime;
       
    }

    //Will Come Back To
    function renew(uint256 _tokenID) external payable {

    }

    function setTokenState(uint256 _tokenID) public {
        //if(smething) {
            //s_cardAttributes[_tokenId].cardState == CardValid.VALID
        //}
        //else {
            //s_cardAttributes[_tokenId].cardState == CardValid.NONVALID
        //}
    } 

    //Token Metadata Will Come Back To
    function updateURI(uint256 _tokenId) private {
       
        string memory subStatus = subscriptionStatus[0];

       if (s_cardAttributes[_tokenId].cardState == CardValid.NONVALID) {
 
            subStatus = subscriptionStatus[0];

        } else if (s_cardAttributes[_tokenId].cardState == CardValid.VALID) {
 
             subStatus = subscriptionStatus[1];
        } 
 
        string memory URIStatus = string(abi.encodePacked(subStatus));
        s_cardAttributes[_tokenId].imgURI = URIStatus;
        _setTokenURI(_tokenId, tokenURI(_tokenId));
    }
 
    //On Chain Token URI - switch to IPFS Or FILE COIN
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        cardAttributes memory m_cardAttributes = s_cardAttributes [_tokenId];
 
        string memory m_cardRate = Strings.toString(m_cardAttributes.rateAmount);
       
        //On-Chain Attributes
        string memory json = string(
            abi.encodePacked(
                '{"name": "Rent An Account",',
                '"description": "',
                //'"image": "',
                m_cardAttributes.imgURI,
                '",',
                '"traits": [',
                '{"trait_type": "Term","value": ',
                m_cardRate,
                "}]",
                "}"
            )
        );
       
        string memory output = string(abi.encodePacked(json));
        return output;
    }

    function getTokenCredentials(uint256 _tokenID) public view returns (bytes32) {
        require(ownerOf(_tokenID) == msg.sender, "not owner");
        require(s_cardAttributes[_tokenID].subscriptionTime > block.timestamp);

        return s_cardAttributes[_tokenID].credentials;
        
    }

    function getTotalSupply() public view returns (uint256) {
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
    function balanceOfContract() public view  returns (uint256) {
        return address(this).balance;
    }
 
    //TESTING
    function getcurrentTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    //TESTING - get tokenUri function 
    function getTokenUri(uint256 _tokenId) public view returns (string memory){
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
 
 
