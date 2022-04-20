//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./KittyContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketplaceContract is Ownable {
    KittyContract private _kittyContract;

    struct Offer {
        address payable seller;
        uint256 price;
        uint256 index;
        uint256 tokenId;
        bool active;
    }

    Offer[] offers;

    event MarketTransaction(bytes32 indexed TxType, address indexed owner, uint256 indexed tokenId);

    mapping(uint256 => Offer) tokenIdToOffer;

    function setKittyContract(address kittyContractAddress) public onlyOwner {
        _kittyContract = KittyContract(kittyContractAddress);
    }

    constructor(address _kittyContractAddress) {
        setKittyContract(_kittyContractAddress);
    }

    function getOffer(uint256 _tokenId)
        public
        view
        returns (
            address seller,
            uint256 price,
            uint256 index,
            uint256 tokenId,
            bool active
        )
    {
        Offer storage offer = tokenIdToOffer[_tokenId];
        return (offer.seller, offer.price, offer.index, offer.tokenId, offer.active);
    }

    function getAllTokenOnSale() public view returns (uint256[] memory listOfOffers) {
        uint256 totalOffers = offers.length;

        if (totalOffers == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](totalOffers);

            uint256 offerId;

            for (offerId = 0; offerId < totalOffers; offerId++) {
                if (offers[offerId].active == true) {
                    result[offerId] = offers[offerId].tokenId;
                }
            }
            return result;
        }
    }

    function _ownsKitty(address _address, uint256 _tokenId) internal view returns (bool) {
        return (_kittyContract.ownerOf(_tokenId) == _address);
    }

    function setOffer(uint256 price, uint256 tokenId) public {
        require(_ownsKitty(msg.sender, tokenId), "Not the owner");
        require(tokenIdToOffer[tokenId].active == false, "You can't sell twice the same offer!");
        require(_kittyContract.isApprovedForAll(msg.sender, address(this)), "Unapproved for all");

        Offer memory _offer = Offer(payable(msg.sender), price, offers.length, tokenId, true);

        tokenIdToOffer[tokenId] = _offer;
        offers.push(_offer);

        emit MarketTransaction("Create offer", msg.sender, tokenId);
    }

    function removeOffer(uint256 tokenId) public {
        Offer memory _offer = tokenIdToOffer[tokenId];
        require(_offer.seller == msg.sender, "Not the seller");

        delete tokenIdToOffer[tokenId];
        offers[tokenIdToOffer[tokenId].index].active = false;

        emit MarketTransaction("Remove offer", msg.sender, tokenId);
    }

    function buyKitty(uint256 tokenId) public payable {
        Offer memory _offer = tokenIdToOffer[tokenId];
        require(msg.value == _offer.price, "Incorrect price");
        require(tokenIdToOffer[tokenId].active = true, "No active order");

        delete tokenIdToOffer[tokenId];
        offers[tokenIdToOffer[tokenId].index].active = false;

        if (_offer.price > 0) {
            _offer.seller.transfer(_offer.price);
        }

        _kittyContract.transferFrom(_offer.seller, msg.sender, tokenId);

        emit MarketTransaction("Buy", msg.sender, tokenId);
    }
}
