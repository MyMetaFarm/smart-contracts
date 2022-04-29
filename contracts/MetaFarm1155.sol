//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGovernance.sol";

contract MetaFarm1155 is ERC1155, Ownable {
    using Strings for uint256;
    IGovernance public gov;

    bytes32 public constant MARKETPLACE = keccak256("MARKETPLACE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant AUTHENTICATOR_ROLE =
        keccak256("AUTHENTICATOR_ROLE");

    modifier onlyManager() {
        require(
            gov.hasRole(MANAGER_ROLE, _msgSender()),
            "Caller is not Manager"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            gov.hasRole(AUTHENTICATOR_ROLE, _msgSender()),
            "Caller is not AUTHENTICATOR"
        );
        _;
    }

    modifier isMaintenance() {
        require(!gov.locked(), "Under Maintenance");
        _;
    }

    event Breed(
        address indexed token,
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount
    );

    constructor(address _gov, string memory _baseURI) ERC1155(_baseURI) {
        gov = IGovernance(_gov);
    }

    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public minted;

    /**
        @notice Update new address of Governance contract
        @dev  Caller must have MANAGER_ROLE
        @param _newGov           New address of Governance contract
    */
    function updateGov(address _newGov) external onlyOwner {
        require(_newGov != address(0), "Set Zero Address");
        gov = IGovernance(_newGov);
    }

    /**
        @notice Update new BaseURI
        @dev  Caller must have MANAGER_ROLE
        @param _newBaseURI    New String of BaseURI
    */
    function updateBaseURI(string calldata _newBaseURI) external onlyManager {
        require(bytes(_newBaseURI).length != 0, "Empty BaseURI");
        _setURI(_newBaseURI);
    }

    /**
        @notice Update Max_Supply of one `tokenId`
        @dev  Caller must have MANAGER_ROLE
        @param _tokenId         Number ID of token
        @param _max             Max of copies that `tokenId` could have
        Note: This function allows MANAGER_ROLE to change MAX_SUPPLY of one `tokenId`
    */
    function setMaxSupply(uint256 _tokenId, uint256 _max) external onlyManager {
        require(_max != 0, "Set zero amount");
        maxSupply[_tokenId] = _max;
    }

    /**
       @notice Query TokenURI of one `_tokenId`
       @dev  Caller can be ANY
       @param _tokenId          Number ID of Token
    */
    function tokenURI(uint256 _tokenId)
        external
        view
        returns (string memory _tokenURI)
    {
        _tokenURI = string(
            abi.encodePacked(uri(_tokenId), _tokenId.toString())
        );
    }

    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyMinter {
        //  when `maxSupply[id] = 0`, allow unlimited minting
        uint256 _max = maxSupply[_tokenId];
        uint256 _minted = minted[_tokenId];
        require(_max == 0 || _minted + _amount <= _max, "Reach max_supply");

        minted[_tokenId] = _minted + _amount;

        _mint(_to, _tokenId, _amount, "");

        emit Breed(address(this), _to, _tokenId, _amount);
    }

    /**
       @notice Override checking `isApprovedForAll`
       Note: MARKETPLACE contract will be assigned an operator and set `true` to bypass checking for approval
    */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (gov.hasRole(MARKETPLACE, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal isMaintenance override {
        require(
            !gov.blacklist(from) && !gov.blacklist(to),
            "User in the blacklist"
        );

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
