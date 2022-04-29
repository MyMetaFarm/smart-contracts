//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IEventWhitelist.sol";
import "./interfaces/IMetaFarm721.sol";
import "./interfaces/IMetaFarm1155.sol";

contract Metaverse is Ownable {
    event MetaverseEventClaimed(
        address indexed user,
        uint256 indexed eventId,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 claimType,
        address token
    );

    struct MetaverseEvent {
        uint256 id;
        uint256 fromDate;
        uint256 toDate;
        uint256 tokenId;
        uint256 amount;
        IEventWhitelist whitelistContract;
        address nft1155Contract;
        address nft721Contract;
        uint256 nftType;
    }

    mapping(uint256 => MetaverseEvent) public metaverseEvents;
    mapping(uint256 => mapping(address => bool)) public metaverseEventClaims;

    function addMetaverseEvent(
        uint256 _id,
        uint256 _fromDate,
        uint256 _toDate,
        uint256 _tokenId,
        uint256 _amount,
        address _whitelistContract,
        address _nftContract,
        uint256 _nftType
    ) external onlyOwner {
        require(
            metaverseEvents[_id].id == 0,
            "Metaverse: airdrop event is existed"
        );
        require(
            _nftType == 1155 || _nftType == 721,
            "Metaverse: invalid event NFT type"
        );
        metaverseEvents[_id] = MetaverseEvent({
            id: _id,
            fromDate: _fromDate,
            toDate: _toDate,
            tokenId: _tokenId,
            amount: _amount,
            whitelistContract: IEventWhitelist(_whitelistContract),
            nftType: _nftType,
            nft1155Contract: _nftType == 1155 ? _nftContract : address(0x0),
            nft721Contract: _nftType == 721 ? _nftContract : address(0x0)
        });
    }

    function claim1155Event(uint256 _id) external {
        MetaverseEvent memory eventInfo = metaverseEvents[_id];
        require(eventInfo.id > 0, "Metaverse: invalid event to join");
        require(
            block.timestamp >= eventInfo.fromDate,
            "Metaverse: event is not started"
        );
        require(
            block.timestamp <= eventInfo.toDate,
            "Metaverse: event is done"
        );
        require(eventInfo.nftType == 1155, "Metaverse: invalid input value");
        address userAddress = _msgSender();
        require(
            eventInfo.whitelistContract.isInWhitelist(userAddress),
            "Metaverse: you are not in whitelist to receive event gifts"
        );
        require(
            metaverseEventClaims[_id][userAddress] == false,
            "Metaverse: invalid action"
        );
        IMetaFarm1155 nftContract = IMetaFarm1155(eventInfo.nft1155Contract);
        nftContract.mint(userAddress, eventInfo.tokenId, eventInfo.amount);
        metaverseEventClaims[_id][userAddress] = true;
        emit MetaverseEventClaimed(
            userAddress,
            _id,
            eventInfo.tokenId,
            eventInfo.amount,
            eventInfo.nftType,
            eventInfo.nft1155Contract
        );
    }

    function claim721Event(uint256 _id, uint256 _tokenId) external {
        MetaverseEvent memory eventInfo = metaverseEvents[_id];
        require(eventInfo.id > 0, "Metaverse: invalid event to join");
        require(
            block.timestamp >= eventInfo.fromDate,
            "Metaverse: event is not started"
        );
        require(
            block.timestamp <= eventInfo.toDate,
            "Metaverse: event is done"
        );
        require(eventInfo.nftType == 721, "Metaverse: invalid input value");
        address userAddress = _msgSender();
        require(
            eventInfo.whitelistContract.isInWhitelist(_msgSender()),
            "Metaverse: you are not in whitelist to receive event gifts"
        );
        require(
            metaverseEventClaims[_id][userAddress] == false,
            "Metaverse: invalid action"
        );
        IMetaFarm721 nftContract = IMetaFarm721(eventInfo.nft721Contract);
        nftContract.safeMint(userAddress, _tokenId);
        metaverseEventClaims[_id][userAddress] = true;
        emit MetaverseEventClaimed(
            userAddress,
            _id,
            _tokenId,
            eventInfo.amount,
            eventInfo.nftType,
            eventInfo.nft721Contract
        );
    }
}
