// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
   @title IArchive contract
   @dev Provide interfaces that other contract can interact
*/
interface IArchive {
    function usedSigs(bytes32 _hash) external view returns (bool);

    /**
        @notice Save hash of a signature
        @dev Caller must be Marketplace conctract
        @param _sigHash             Hash of signature
    */
    function record(bytes32 _sigHash) external;
}
