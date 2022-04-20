//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KittyContract is Ownable, ERC721 {
    constructor() ERC721("Rein Kitties", "RK") {
        _createKitty(0, 0, 0, owner(), 1 gwei);
    }

    event Birth(address indexed owner, uint256 indexed kittyId);

    uint32 CREATION_LIMIT_GEN0 = 69;
    uint256 gen0Counter = 0;
    uint256 private gen0Price = 0.1 ether;

    struct Kitty {
        uint256 genes;
        uint256 birthTime;
        uint256 momId;
        uint256 dadId;
        uint32 generation;
    }

    Kitty[] kitties;

    function getKitty(uint256 kittyId)
        external
        view
        returns (
            uint256 genes,
            uint256 birthTime,
            uint256 momId,
            uint256 dadId,
            uint32 generation
        )
    {
        Kitty storage kitty = kitties[kittyId];
        return (kitty.genes, kitty.birthTime, kitty.momId, kitty.dadId, kitty.generation);
    }

    function totalSupply() public view returns (uint256) {
        return kitties.length;
    }

    function getGen0Price() public view returns (uint256) {
        return gen0Price;
    }

    function setGen0Price(uint256 price) public onlyOwner {
        gen0Price = price;
    }

    function withdraw(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function createKittyGen0(uint256 genes) public payable {
        require(gen0Counter < CREATION_LIMIT_GEN0, "Gen0 creation over limit");
        require((msg.sender != owner() || msg.sender != address(this)) && msg.value == gen0Price, "Invalid price");

        gen0Counter++;

        _createKitty(genes, 0, 0, msg.sender, 0);
    }

    function breed(uint256 momId, uint256 dadId) public returns (uint256) {
        require(ownerOf(momId) == msg.sender, "Not the owner of mom");
        require(ownerOf(dadId) == msg.sender, "Not the owner of dad");

        uint256 newDna = _mixDna(momId, dadId);
        uint32 generation = _getGeneration(momId, dadId);

        return _createKitty(newDna, momId, dadId, msg.sender, generation);
    }

    function _getGeneration(uint256 momId, uint256 dadId) private view returns (uint32) {
        uint32 momGen = kitties[momId].generation;
        uint32 dadGen = kitties[dadId].generation;
        uint32 newGen = momGen >= dadGen ? momGen : dadGen;
        return newGen + 1;
    }

    function _mixDna(uint256 momId, uint256 dadId) internal view returns (uint256) {
        // 11 22 33 44 55 66 77 88 99
        uint256 momDna = kitties[momId].genes;
        uint256 dadDna = kitties[dadId].genes;

        uint256[8] memory geneArray;

        // binary 0-255
        uint8 random = uint8(block.timestamp % 255);
        uint256 index = 7;
        for (uint256 i = 1; i <= 128; i = i * 2) {
            if (random & i != 0) {
                geneArray[index] = momDna % 100;
            } else {
                geneArray[index] = dadDna % 100;
            }
            momDna = momDna / 100;
            dadDna = dadDna / 100;
            if (index > 0) {
                index = index - 1;
            }
        }

        uint256 newGene;
        for (uint256 i = 0; i < 8; i++) {
            newGene = newGene + geneArray[i];
            if (i != 7) {
                newGene = newGene * 100;
            }
        }

        return newGene;
    }

    function _createKitty(
        uint256 genes,
        uint256 momId,
        uint256 dadId,
        address owner,
        uint32 generation
    ) private returns (uint256 tokenId) {
        // uint32 generation = momId == 0 ? 0 : kitties[momId].generation + 1;
        Kitty memory _kitty = Kitty(genes, block.timestamp, momId, dadId, generation);
        kitties.push(_kitty);
        uint256 kittyId = kitties.length - 1;

        _safeMint(owner, kittyId);

        emit Birth(owner, kittyId);

        return kittyId;
    }
}
