// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library Proposals {
    struct RentLandProposal {
        address proposer;
        uint256 startTileX;
        uint256 startTileY;
        uint256 width;
        uint256 height;
        uint256 duration;
        uint256 tokenId;
        address handlerAddress;
    }

    function calcuateBlockArea(RentLandProposal memory rentProposal)
        internal
        pure
        returns (uint256)
    {
        return rentProposal.width * rentProposal.height;
    }

    function getExpireAt(RentLandProposal memory rentProposal)
        internal
        view
        returns (uint256)
    {
        return block.timestamp + rentProposal.duration;
    }
}
