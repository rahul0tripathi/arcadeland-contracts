// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Counters} from "../lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {ERC721URIStorage} from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Land} from "./rentedLands.sol";
import {Proposals} from "./library/proposal.sol";

contract ArcadeLand is ERC721, Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;

    string public constant SYMBOL = "ARC";
    string public constant NAME = "arcland";
    uint256 public constant MAP_HEIGHT = 100;

    uint256 private _blockPrice = 0;
    uint256 private _maxSupply;
    Counters.Counter private _landIds;
    uint256 public immutable baseMintPrice;

    mapping(uint256 => address) public lands;

    constructor(
        uint256 maxSupply,
        uint256 blockPrice,
        uint256 MintPrice
    ) ERC721(NAME, SYMBOL) {
        require(blockPrice > 0, "blockPrice too low");
        require(maxSupply > 0, "maxSupply too less");
        _maxSupply = maxSupply;
        _blockPrice = blockPrice;
        baseMintPrice = MintPrice;
    }

    function mint(string memory _map) public payable returns (uint256) {
        require(msg.value == baseMintPrice, "Insufficent amount");
        _landIds.increment();
        uint256 newLandId = _landIds.current();
        _safeMint(msg.sender, newLandId);
        _setTokenURI(newLandId, _map);
        lands[newLandId] = address(new Land(msg.sender, MAP_HEIGHT));
        return newLandId;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        //super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
