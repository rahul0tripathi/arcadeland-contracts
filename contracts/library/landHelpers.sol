// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {Proposals} from "./proposal.sol";
import "hardhat/console.sol";

library LandHelpers {
    struct RentedLands {
        uint256 proposalId;
        Proposals.RentLandProposal proposal;
        bool approved;
        uint256 amount;
        bool isValue;
        uint256 expireAt;
        uint256 position;
    }

    function getOccupiyingBlocks(
        Proposals.RentLandProposal memory proposal,
        uint256 _mapHeight
    ) internal view returns (uint256[] memory) {
        uint256[] memory blockList = new uint256[](
            proposal.height * proposal.width
        );

        uint256 arrPointer = 0;
        uint256 pointer = proposal.startTileY == 0
            ? 1 * (_mapHeight)
            : (proposal.startTileY - 1) * (_mapHeight);
        if (proposal.startTileX > 0) {
            pointer += proposal.startTileX;
        }
        console.log("pointer", pointer);
        for (uint256 i = 0; i < proposal.height; i++) {
            for (uint256 j = 0; j < proposal.width; j++) {
                console.log("arrPointer", arrPointer);
                blockList[arrPointer] = pointer + j;
                arrPointer++;
            }
            pointer += _mapHeight;
        }
        return blockList;
    }

    function checkCollision(
        mapping(uint256 => uint256) storage currentState,
        Proposals.RentLandProposal memory proposal,
        mapping(uint256 => RentedLands) storage rentMap,
        uint256 _mapHeight
    ) internal view returns (bool, uint256) {
        bool collides = false;
        uint256 latestExpire = 0;
        uint256 owner = 0;
        uint256[] memory blockList = getOccupiyingBlocks(proposal, _mapHeight);
        for (uint256 i = 0; i < blockList.length; i++) {
            if (currentState[blockList[i]] > 0) {
                collides = true;
                owner = currentState[blockList[i]];
                latestExpire = rentMap[owner].expireAt;
                break;
            }
        }
        // if (collides && owner > 0) {
        //     collides = false;
        // }
        return (collides, owner);
    }
}
