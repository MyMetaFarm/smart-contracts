// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Test is ERC721 {
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address _to, uint256 _fromID, uint256 _amount) external {
        for (uint256 i = _fromID; i < _fromID + _amount; i++) {
			_safeMint(_to, i);
		}
    }
}