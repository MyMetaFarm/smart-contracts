// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
   @title IGovernance interface
   @dev This provides interfaces that other contracts can interact with Governance contract
*/
interface IGovernance {
    function locked() external view returns (bool);
    function treasury() external view returns (address);
    function listOfNFTs(address _nftContr) external view returns (bool);
    function blacklist(address _account) external view returns (bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function paymentTokens(address _token) external view returns (bool);
    function FEE_DENOMINATOR() external view returns (uint256);
    function commissionFee() external view returns (uint256);
}
