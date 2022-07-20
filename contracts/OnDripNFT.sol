// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

error Payments__Failed();

contract OnDripNFT is ERC721, ERC2981, ERC721URIStorage, ERC721Enumerable {
    using Counters for Counters.Counter;

    bool public s_mintLive;
    uint96 s_royaltyFeeBips;

    uint256 public immutable maxInterval = 15768000; //six months
    uint256 public immutable minInterval = 10800; //three hours

    address public s_contractOwner;

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

    mapping(uint256 => cardAttributes) private s_cardAttributes;

    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint96 _royaltyFeeBips
    ) ERC721(_name, _symbol) {
        s_contractOwner = _owner;
        s_royaltyFeeBips = _royaltyFeeBips;
    }

    //EVENTS
    event AccountMinted(
        address indexed _accountOwner,
        uint256 _id,
        string _description,
        uint256 _rateAmount,
        uint256 __renewalFee,
        bytes32 _credentials,
        bool _active
    );
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event SubscriptionStatus(
        address indexed _renter,
        uint256 _tokenID,
        address indexed _receiver,
        bool _active
    );
    event SubscriptionUpdate(
        address indexed _renter,
        uint256 _tokenID,
        uint256 _hour,
        address indexed _receiver,
        uint256 _amount
    ); //prob can only do time ...
    event FundsWithdrawn(address indexed _from, address indexed _to);
    event CredientialsUpdated(uint256 _tokenID, bytes32 credientials);
    //OPTIONAL MODIFIER - When Called Pre Function It Checks On Time Expiry Of SUB
    modifier onlyOwner() {
        require(msg.sender == s_contractOwner);
        _;
    }

    modifier getTokeValid(uint256 _tokenID) {
        address renter = ownerOf(_tokenID);
        if (s_cardAttributes[_tokenID].subscriptionTime <= block.timestamp) {
            s_cardAttributes[_tokenID].cardValid = false;
        } else if (
            s_cardAttributes[_tokenID].subscriptionTime >= block.timestamp
        ) {
            s_cardAttributes[_tokenID].cardValid = true;
        }

        emit SubscriptionStatus(
            renter,
            _tokenID,
            s_cardAttributes[_tokenID].accountOwner,
            s_cardAttributes[_tokenID].cardValid
        );
        _;
    }

    function mint(
        string memory _vendorURI,
        string memory _description,
        uint256 _rateAmount,
        uint256 _renewalFee
    ) external {
        //require(s_mintLive, "Mint isn't live");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        s_cardAttributes[tokenId] = cardAttributes({
            accountOwner: payable(msg.sender),
            description: _description,
            imgURI: _vendorURI, //IPFS HASH
            rateAmount: _rateAmount,
            renewalFee: _renewalFee,
            credentials: "0x",
            subscriptionTime: block.timestamp,
            cardValid: false
        });

        _setTokenRoyalty(tokenId, msg.sender, s_royaltyFeeBips); //USER MAY SET THIER OWN ROYALTY
        _setTokenURI(tokenId, tokenURI(tokenId));
        emit AccountMinted(
            msg.sender,
            tokenId,
            _description,
            _rateAmount,
            _renewalFee,
            "0x",
            false
        );
    }

    function topUp(uint256 _tokenID) external payable {
        require(ownerOf(_tokenID) == msg.sender, "not owner");
        require(
            s_cardAttributes[_tokenID].cardValid == true,
            "Card not active"
        );

        uint256 newTime = calculateSubscriptionTime(msg.value, _tokenID);

        if (newTime >= minInterval && newTime <= maxInterval) {
            s_cardAttributes[_tokenID].subscriptionTime +=
                block.timestamp +
                newTime;
            address receiver = s_cardAttributes[_tokenID].accountOwner;
            (bool success, ) = receiver.call{value: msg.value}("");
            require(success, "Transfer failed");
        } else {
            revert Payments__Failed();
        }
    }

    function calculateSubscriptionTime(uint256 _amount, uint256 _tokenID)
        internal
        returns (uint256)
    {
        require(
            _amount >= s_cardAttributes[_tokenID].rateAmount,
            "too little payment"
        );
        require(
            _amount >= s_cardAttributes[_tokenID].rateAmount * 3,
            "3 hour minimum"
        );

        address currentSub = ownerOf(_tokenID);
        uint256 hour = _amount / s_cardAttributes[_tokenID].rateAmount;
        uint256 newTime = (hour * 60) * 60;

        emit SubscriptionUpdate(
            currentSub,
            _tokenID,
            hour,
            s_cardAttributes[_tokenID].accountOwner,
            _amount
        );

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

        emit SubscriptionStatus(
            msg.sender,
            _tokenID,
            s_cardAttributes[_tokenID].accountOwner,
            s_cardAttributes[_tokenID].cardValid
        );
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
        string memory strRate = Strings.toString(cardAttr.rateAmount);
        string memory strFee = Strings.toString(cardAttr.renewalFee);
        //string memory strSub = Strings.toString(cardAttr.subscriptionTime);

        bytes memory m1 = abi.encodePacked(
            '{"name":"',
            name(),
            "Description",
            '", "description":"',
            s_cardAttributes[tokenId].description,
            "Subscription",
            '", "image": "',
            imageURI,
            // adding policyHolder
            '", "attributes": [{"trait_type":"Top Off Rate",',
            '"value":"',
            strRate,
            '"}, {"trait_type": "Renewal Rate", ',
            '"value":"',
            strFee,
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

    function updateTokenCredentials(bytes32 _credentials, uint256 _tokenId)
        external
        onlyOwner
    {
        s_cardAttributes[_tokenId].credentials = _credentials;
        emit CredientialsUpdated(_tokenID, _credentials);
    }

    function accessToCredentials(uint256 _tokenID)
        public
        returns (bool access)
    {
        if (s_cardAttributes[_tokenID].subscriptionTime > block.timestamp) {
            s_cardAttributes[_tokenID].cardValid = true;
            return true;
        } else if (
            s_cardAttributes[_tokenID].subscriptionTime <= block.timestamp
        ) {
            s_cardAttributes[_tokenID].cardValid = false;
            return false;
        }
    }

    //GETTER FUNCTION IF NEEDED
    function getTokenCredentials(uint256 _tokenID)
        public
        view
        returns (bytes32)
    {
        require(ownerOf(_tokenID) == msg.sender, "not owner");
        require(s_cardAttributes[_tokenID].subscriptionTime > block.timestamp);
        require(
            s_cardAttributes[_tokenID].cardValid == true,
            "Card not active"
        );

        return s_cardAttributes[_tokenID].credentials;
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
}
