// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {Counters} from "../lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {Proposals} from "./library/proposal.sol";
import "./library/landHelpers.sol";
import "hardhat/console.sol";

contract Land {
    enum UpdateStatus {
        REFUNDED,
        APPROVED,
        ERRUNAUTHORIZED
    }
    using Counters for Counters.Counter;
    using Proposals for *;
    using LandHelpers for *;
    address private _owner;
    uint256 private _mapHeight;
    Counters.Counter private _poposalCount;

    mapping(uint256 => uint256) public _tileOwners;
    LandHelpers.RentedLands[] public rentedAssets;
    uint256 public pendingProposal;
    mapping(uint256 => LandHelpers.RentedLands) public _rents;

    constructor(address owner, uint256 height) {
        _owner = owner;
        _mapHeight = height;
    }

    function getRentedLands()
        external
        view
        returns (LandHelpers.RentedLands[] memory)
    {
        return rentedAssets;
    }

    function _removeRentedLand(uint256 id) internal returns (bool) {
        require(_rents[id].isValue, "rent does not exist");
        LandHelpers.RentedLands memory currentRent = _rents[id];
        uint256[] memory blocksToOccupy = LandHelpers.getOccupiyingBlocks(
            currentRent.proposal,
            _mapHeight
        );

        for (uint256 i = 0; i < blocksToOccupy.length; i++) {
            _tileOwners[blocksToOccupy[i]] = 0;
        }

        LandHelpers.RentedLands memory lastLand = _rents[
            rentedAssets[rentedAssets.length - 1].proposalId
        ];
        require(lastLand.isValue, "failed to get last rentedAssets");
        lastLand.position = currentRent.position;
        rentedAssets[currentRent.position] = lastLand;
        rentedAssets.pop();
        delete _rents[id];
        return true;
    }

    function _addRentLandProposal(
        Proposals.RentLandProposal memory proposal,
        uint256 _amount
    ) internal returns (uint256) {
        (bool collides, uint256 owner) = LandHelpers.checkCollision(
            _tileOwners,
            proposal,
            _rents,
            _mapHeight
        );
        console.log("collides", collides);
        console.log("owner", owner);
        require(!collides, "proposal collision detected");
        if (owner > 0) {
            bool removed = _removeRentedLand(owner);
            require(removed, "failed to remove existing owner");
        }
        uint256[] memory blocksToOccupy = LandHelpers.getOccupiyingBlocks(
            proposal,
            _mapHeight
        );

        _poposalCount.increment();
        uint256 proposalId = _poposalCount.current();

        console.log("proposalId", proposalId);
        for (uint256 i = 0; i < blocksToOccupy.length; i++) {
            _tileOwners[blocksToOccupy[i]] = proposalId;
        }
        _rents[proposalId] = LandHelpers.RentedLands({
            proposalId: proposalId,
            proposal: proposal,
            isValue: true,
            expireAt: Proposals.getExpireAt(proposal),
            position: rentedAssets.length,
            approved: false,
            amount: _amount
        });
        _addProposalToQueue(proposalId);
        return proposalId;
    }

    function newProposal(
        uint256 startTileX,
        uint256 startTileY,
        uint256 width,
        uint256 height,
        uint256 duration,
        uint256 tokenId,
        address handlerAddress
    ) external payable emptyProposalPool returns (uint256) {
        // if (
        //     IERC165(handlerAddress).supportsInterface(type(IERC721).interfaceId)
        // ) {
        //     address ownerOfOriginal = IERC721(handlerAddress).ownerOf(tokenId);
        //     require(
        //         ownerOfOriginal != address(0x0) &&
        //             ownerOfOriginal == msg.sender,
        //         "sender is not the owner"
        //     );
        Proposals.RentLandProposal memory proposal = Proposals.RentLandProposal(
            msg.sender,
            startTileX,
            startTileY,
            width,
            height,
            duration,
            tokenId,
            handlerAddress
        );
        uint256 proposalId = _addRentLandProposal(proposal, msg.value);
        return proposalId;
        // } else {
        //     revert("unsupported interface");
        // }
    }

    function updateProposalStatus(bool approve)
        external
        returns (UpdateStatus)
    {
        require(
            pendingProposal > 0 && _rents[pendingProposal].isValue,
            "proposalPool is empty"
        );
        require(
            msg.sender == _owner ||
                _rents[pendingProposal].proposal.proposer == msg.sender,
            "not allowed"
        );
        if (msg.sender == _owner) {
            if (approve) {
                _approveProposal();
                return UpdateStatus.APPROVED;
            } else {
                _refundProposal();
                return UpdateStatus.REFUNDED;
            }
        } else if (_rents[pendingProposal].proposal.proposer == msg.sender) {
            _refundProposal();
            return UpdateStatus.REFUNDED;
        } else {
            return UpdateStatus.ERRUNAUTHORIZED;
        }
    }

    function _addProposalToQueue(uint256 id) internal emptyProposalPool {
        pendingProposal = id;
    }

    function _approveProposal() internal {
        _rents[pendingProposal].approved = true;
        rentedAssets.push(_rents[pendingProposal]);
        pendingProposal = 0;
    }

    function _refundProposal() internal {
        delete _rents[pendingProposal];
        uint256 currentProposal = pendingProposal;
        pendingProposal = 0;
        payable(_rents[currentProposal].proposal.proposer).transfer(
            _rents[currentProposal].amount
        );
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "invalid caller");
        _;
    }
    modifier emptyProposalPool() {
        require(pendingProposal == 0, "proposalPool is not empty");
        _;
    }
}
