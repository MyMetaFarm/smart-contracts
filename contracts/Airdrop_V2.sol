// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IGovernance.sol";

/**
   @title AirDrop contract
   @dev This contract (version 2) is being used to support Air Drop event
       + Foundation already minted NFT items 
       + Users (qualified) call to claim, then NFTs are transferred to users
*/
contract AirDropV2 is Context {
    IGovernance public gov;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant VERSION = keccak256("AIRDROP_v2");
    uint256 public constant NFT721 = 721;
    uint256 public constant NFT1155 = 1155;

    mapping(uint256 => bytes32) public roots;
    mapping(uint256 => mapping(address => bool)) public claimed;

    event Drop(
        uint256 indexed eventID,
        address indexed token,
        address indexed receiver,
        uint256 nftType,
        uint256 tokenID,
        uint256 amount
    );

    modifier onlyAdmin() {
        require(gov.hasRole(ADMIN_ROLE, _msgSender()), "Caller is not Admin");
        _;
    }

    modifier onlyManager() {
        require(
            gov.hasRole(MANAGER_ROLE, _msgSender()),
            "Caller is not Manager"
        );
        _;
    }

    constructor(address _gov) {
        gov = IGovernance(_gov);
    }

    /**
       	@notice Update Address of Governance contract
       	@dev  Caller must have ADMIN_ROLE
		@param	_gov				Address of Governance contract (or address(0))
		Note: When `_gov = address(0)`, Air Drop contract is deprecated
    */
    function setGOV(address _gov) external onlyAdmin {
        gov = IGovernance(_gov);
    }

    /**
       	@notice Set Root Hash of the Special Event
       	@dev  Caller must have MANAGER_ROLE
		@param	_eventID			ID of Special Event
		@param 	_root				Root Hash
    */
    function setRoot(uint256 _eventID, bytes32 _root) external onlyManager {
        require(roots[_eventID] == "", "EventID recorded");
        require(_root != "", "Empty Hash");
        roots[_eventID] = _root;
    }

    /**
       	@notice Claim Air Drop/Special Event
       	@dev  Caller can be ANY
		@param	_eventID				ID of Special Event
		@param	_tokenID				TokenID of item about to transfer to `msg.sender`
		@param	_distributor			Wallet's address that holds NFTs/Heroes of Air Drop event
		@param	_token					Address of NFT/Token contract 
		@param	_proof					An array of proof
    */
    function claim(
        uint256 _eventID,
        uint256 _tokenID,
        uint256 _nftType,
        uint256 _amount,
        address _distributor,
        address _token,
        bytes32[] calldata _proof
    ) external {
        require(address(gov) != address(0), "Out of Service");
        require(gov.listOfNFTs(_token), "Contract not supported");
        require(
            _nftType == NFT721 || _nftType == NFT1155,
            "Type not supported"
        );
        if (_nftType == NFT721)
            require(_amount == 1, "Invalid claiming amount");

        address _user = _msgSender();
        bytes32 _root = roots[_eventID];
        require(_root != "", "EventID not recorded");
        require(!claimed[_eventID][_user], "Already claimed");

        claimed[_eventID][_user] = true;
        bytes32 _leaf = keccak256(
            abi.encodePacked(
                _user,
                _tokenID,
                _eventID,
                _nftType,
                _token,
                _amount,
                _distributor
            )
        );
        require(
            MerkleProof.verify(_proof, _root, _leaf),
            "Invalid claiming request"
        );

        if (_nftType == NFT721)
            IERC721(_token).safeTransferFrom(_distributor, _user, _tokenID);
        else
            IERC1155(_token).safeTransferFrom(
                _distributor,
                _user,
                _tokenID,
                _amount,
                ""
            );

        emit Drop(_eventID, _token, _user, _nftType, _tokenID, _amount);
    }
}
