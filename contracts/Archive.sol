// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGovernance.sol";

/**
   @title Archive contract
   @dev This contract archives used signatures
*/
contract Archive {
    IGovernance public gov;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MARKETPLACE = keccak256("MARKETPLACE");

    //  Hash(signature) will be recorded in the list
    mapping(bytes32 => bool) public usedSigs;

    modifier onlyAuthorize() {
        require(gov.hasRole(MARKETPLACE, msg.sender), "Unauthorized ");
        _;
    }

    modifier onlyManager() {
        require(gov.hasRole(MANAGER_ROLE, msg.sender), "Caller is not Manager");
        _;
    }

    constructor(address _gov) {
        gov = IGovernance(_gov);
    }

    /**
        @notice Change a new Manager contract
        @dev Caller must be Owner
        @param _newGov       Address of new Governance Contract
    */
    function setGov(address _newGov) external onlyManager {
        require(_newGov != address(0), "Set zero address");
        gov = IGovernance(_newGov);
    }

    /**
        @notice Save hash of a signature
        @dev Caller must be Marketplace conctract
        @param _sigHash             Hash of signature
    */
    function record(bytes32 _sigHash) external onlyAuthorize {
        require(!usedSigs[_sigHash], "Signature recorded");
        usedSigs[_sigHash] = true;
    }
}
