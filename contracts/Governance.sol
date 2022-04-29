// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
   @title Governance contract
   @dev This contract is being used as Governance of MyMetaFarm
       + Register address (Treasury) to receive Commission Fee 
       + Set up additional special roles - DEFAULT_ADMIN_ROLE, MANAGER_ROLE and MINTER_ROLE
*/
contract Governance is AccessControlEnumerable {
    uint256 public constant FEE_DENOMINATOR = 10**4;
    uint256 public commissionFee; //  fee_rate = commissionFee / FEE_DENOMINATOR

    address public treasury;

    mapping(address => bool) public listOfNFTs; // Both NFT721 and NFT1155 include in the list
    mapping(address => bool) public blacklist;
    mapping(address => bool) public paymentTokens;

    bool public locked;

    //  Declare Roles - MANAGER_ROLE and MINTER_ROLE
    //  There are three roles:
    //     - Top Gun = DEFAULT_ADMIN_ROLE:
    //          + Manages governance settings
    //          + Has an authority to grant/revoke other roles
    //          + Has an authority to set him/herself other roles
    //     - MANAGER_ROLE
    //          + Has an authority to do special tasks, i.e. settings
    //          + NFT Holder when Heroes/item are minted
    //     - AUTHENTICATOR
    //          + Has an authority to mint NFT items
    //          + Provide signature to authorize a request
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant AUTHENTICATOR_ROLE =
        keccak256("AUTHENTICATOR_ROLE");
    bytes32 public constant MARKETPLACE = keccak256("MARKETPLACE");

    constructor(address _treasury, address[] memory _tokens) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        treasury = _treasury;

        uint256 _size = _tokens.length;
        for(uint256 i; i < _size; i++)
            paymentTokens[ _tokens[i] ] = true;

    }

    /**
       @notice Set `locked = true`
       @dev  Caller must have DEFAULT_ADMIN_ROLE
    */
    function lock() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!locked, "Locked");
        locked = true;
    }

    /**
       @notice Set `locked = false`
       @dev  Caller must have DEFAULT_ADMIN_ROLE
    */
    function unlock() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(locked, "Unlocked");
        locked = false;
    }

    /**
       @notice Change new address of Treasury
       @dev  Caller must have DEFAULT_ADMIN_ROLE
       @param _newTreasury    Address of new Treasury
    */
    function updateTreasury(address _newTreasury)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newTreasury != address(0), "Set zero address");
        treasury = _newTreasury;
    }

    /**
       @notice Set/Update Commission Fee
       @dev  Caller must have MANAGER_ROLE
       @param _newRate          New fee rate of Commission Fee     
    */
    function setCommissionFee(uint256 _newRate)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(_newRate < FEE_DENOMINATOR, "Invalid fee rate");
        commissionFee = _newRate;
    }

    /**
       @notice Register Payment Token (i.e. USDT, USDC, etc)
       @dev  Caller must have MANAGER_ROLE
       @param _token         Address of Token contract
    */
    function addPaymentToken(address _token) external onlyRole(MANAGER_ROLE) {
        require(_token != address(0), "Set zero address");
        require(!paymentTokens[_token], "Token already accepted");
        paymentTokens[_token] = true;
    }

    /**
       @notice Unregister Payment Token
       @dev  Caller must have MANAGER_ROLE
       @param _token         Address of Token contract
    */
    function removePaymentToken(address _token)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(paymentTokens[_token], "Payment not recorded");
        paymentTokens[_token] = false;
    }

    /**
       @notice Register NFT Contract
       @dev  Caller must have MANAGER_ROLE
       @param _nftContr         Address of NFT Contract
    */
    function registerNFT(address _nftContr) external onlyRole(MANAGER_ROLE) {
        require(_nftContr != address(0), "Set zero address");
        require(!listOfNFTs[_nftContr], "Already added");
        listOfNFTs[_nftContr] = true;
    }

    /**
       @notice Unregister NFT Contract
       @dev  Caller must have MANAGER_ROLE
       @param _nftContr         Address of NFT Contract
    */
    function unregisterNFT(address _nftContr) external onlyRole(MANAGER_ROLE) {
        require(listOfNFTs[_nftContr], "Not found");
        listOfNFTs[_nftContr] = false;
    }

    /**
       @notice Add User's address into the blacklist
       @dev  Caller must have MANAGER_ROLE
       @param _account         Address of User that going to be blocked
    */
    function addBlacklist(address _account) external onlyRole(MANAGER_ROLE) {
        require(_account != address(0), "Set zero address");
        require(!blacklist[_account], "Account already in the blacklist");
        blacklist[_account] = true;
    }

    /**
       @notice Remove User's address out of the blacklist
       @dev  Caller must have MANAGER_ROLE
       @param _account         Address of User that going to be removed
    */
    function removeBlacklist(address _account) external onlyRole(MANAGER_ROLE) {
        require(blacklist[_account], "Account not in the blacklist");
        blacklist[_account] = false;
    }
}
