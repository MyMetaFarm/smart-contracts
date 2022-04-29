//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract EventWhitelist is Ownable {
    mapping(address => bool) public whitelists;

    function isInWhitelist(address _user) external view returns (bool) {
        return whitelists[_user];
    }

    function addToWhitelist(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelists[_users[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelists[_users[i]] = false;
        }
    }
}
