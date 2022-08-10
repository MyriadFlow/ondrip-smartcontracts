// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

error Payments__Failed();

//coupon mint from the same contract

contract OnDripNFTDiscount is ERC721, ERC2981, ERC721URIStorage, ERC721Enumerable {
    using Counters for Counters.Counter;

    uint96 s_royaltyFeeBips;

    address public s_contractOwner;
    address public s_nftMarketplace;

    struct cardAttributes {
        address payable accountOwner;
        string description;
        string imgURI;
        string discountCode;
        uint256 uses; //how many uses does this discount have before expiry
        bool cardValid;
    }

    mapping(uint256 => cardAttributes) private s_cardAttributes;

    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _nftMarketPlace,
        uint96 _royaltyFeeBips
    ) ERC721(_name, _symbol) {
        s_contractOwner = _owner;
        s_royaltyFeeBips = _royaltyFeeBips;
        s_nftMarketplace = _nftMarketPlace;
    }

    //EVENTS
    event AccountMinted(
        address indexed _accountOwner,
        uint256 _id,
        string _description,
        bytes32 _discountCode,
        bool _active
    );
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event FundsWithdrawn(address indexed _from, address indexed _to);
    event CredientialsUpdated(uint256 _tokenID, string credientials);
    event UsesLeft(uint256 _tokenID, uint256 credientials);

    modifier onlyOwner() {
        require(msg.sender == s_contractOwner);
        _;
    }

    modifier usesCalculator(uint256 _tokenId) {
        require(msg.sender == s_contractOwner);

        s_cardAttributes[_tokenId].uses = s_cardAttributes[_tokenId].uses - 1;

        _;
    }

    function mint(
        string memory _vendorURI,
        string memory _description,
        uint256 _uses
    ) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        s_cardAttributes[tokenId] = cardAttributes({
            accountOwner:payable(msg.sender),
            description: _description,
            imgURI: _vendorURI, //IPFS HASH
            uses: _uses,
            discountCode: "0x",
            cardValid: false
        });

        _setTokenRoyalty(tokenId, msg.sender, s_royaltyFeeBips); //USER MAY SET THIER OWN ROYALTY
        _setTokenURI(tokenId, tokenURI(tokenId));
        setApprovalForAll(s_nftMarketplace, true); //THIS MAY BE PLACED IN A BETTER SPOT
        emit AccountMinted(
            msg.sender,
            tokenId,
            _description,
            "0x",
            false
        );

        return tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        cardAttributes memory cardAttr = s_cardAttributes[tokenId];

        string memory imageURI = cardAttr.imgURI;
        string memory uses = Strings.toString(cardAttr.uses);
        //string memory strSub = Strings.toString(cardAttr.subscriptionTime);

        bytes memory m1 = abi.encodePacked(
            '{"name":"',
            name(),
            "Description",
            '", "description":"',
            s_cardAttributes[tokenId].description,
            "Discounted Product",
            '", "image": "',
            imageURI,
            // adding policyHolder
            '", "attributes": [{"trait_type":"Uses",',
            '"value":"',
            uses,
            '"}]}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes.concat(m1))
                )
            );
    }

    function calculateUses(uint256 _tokenID)
        external
        onlyOwner
    {
        s_cardAttributes[_tokenID].uses = s_cardAttributes[_tokenID].uses - 1;
        emit UsesLeft(_tokenID, s_cardAttributes[_tokenID].uses);
    }

    function updateTokenCredentials(string memory _discountCode, uint256 _tokenId)
        external
        onlyOwner
    {
        s_cardAttributes[_tokenId].discountCode = _discountCode;
        emit CredientialsUpdated(_tokenId, _discountCode);
    }

    //ACCESS CARD
    function accessToCredentials(uint256 _tokenID)
        public
        view
        returns (bool access)
    {
       if(s_cardAttributes[_tokenID].uses > 0){
           return true;
       }
       else if(s_cardAttributes[_tokenID].uses == 0){
           return false;
       }
    }

    //Possibly Functions For Encoding Or Decoding -- Might Change Password and Username To String  To String - Stringify
    function encode(uint256 password, string memory username)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(password, username);
    }

    //Possibly Functions For Encoding Or Decoding -- Might Change Password and Username To String  To String - Stringify
    function decode(bytes calldata data)
        external
        pure
        returns (uint256 password, string memory username)
    {
        (password, username) = abi.decode(data, (uint256, string));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function balanceOfContract() external view returns (uint256) {
        return address(this).balance;
    }   
    
    function getCurrentEpoch() external view returns (uint256) {
        return block.timestamp;
    }   
         
}