// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";


contract OnDripDL is ERC721, ERC2981, ERC721URIStorage, AccessControlEnumerable {
    using Counters for Counters.Counter;

    uint96 s_royaltyFeeBips;
    bool public paused = false; // Switch critical funcs to be paused

    struct cardAttributes {
        address payable accountOwner;
        string description;
        string imgURI;
        string discountCode;
        bool cardValid;
    }

    mapping(uint256 => cardAttributes) private s_cardAttributes;

    Counters.Counter private _tokenIdCounter;

     //ROLES
    bytes32 public constant OPERATOR =
        keccak256("OPERATOR");

    bytes32 public constant CREATOR =
        keccak256("CREATOR");

    bytes32 public constant OWNER =
        keccak256("OWNER");

    constructor(
        string memory _name,
        string memory _symbol,
        address _platformAddress,
        address _vendorAddress,
        address _nftMarketPlace,
        uint96 _royaltyFeeBips
    ) ERC721(_name, _symbol) {
        _grantRole(OPERATOR, _platformAddress);
        _grantRole(OPERATOR, _vendorAddress);
        _grantRole(OWNER, _vendorAddress);
        _setRoleAdmin(OPERATOR, OPERATOR);
        s_royaltyFeeBips = _royaltyFeeBips;
        setApprovalForAll(_nftMarketPlace, true); 
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

    function mint(
        string memory _saasURI,
        string memory _description
    ) external onlyRole(CREATOR) returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        s_cardAttributes[tokenId] = cardAttributes({
            accountOwner:payable(msg.sender),
            description: _description,
            imgURI: _saasURI, //IPFS HASH
            discountCode: "0x",
            cardValid: false
        });

        _setTokenRoyalty(tokenId, msg.sender, s_royaltyFeeBips); //USER MAY SET THIER OWN ROYALTY
        _setTokenURI(tokenId, tokenURI(tokenId));
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

        bytes memory m1 = abi.encodePacked(
            '{"name":"',
            name(),
            "Description",
            '", "description":"',
            s_cardAttributes[tokenId].description,
            "Discounted Product",
            '", "image": "',
            imageURI,
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

    function updateTokenCredentials(string memory _discountCode, uint256 _tokenId)
        external
        onlyRole(OPERATOR)
    {
        s_cardAttributes[_tokenId].discountCode = _discountCode;
        emit CredientialsUpdated(_tokenId, _discountCode);
    }

    function addToRole(address account) external onlyRole(OPERATOR) {
        grantRole(CREATOR, account);
    }

    function setPaused(bool _paused) external onlyRole(OPERATOR) {
        paused = _paused;
    }

    //ACCESS CARD use once 
    //function accessToCredentials(uint256 _tokenID)
        //public
        //view
        //returns (bool access)
    //{
       
    //}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

}