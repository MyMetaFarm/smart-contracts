//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMetaFarm721 is IERC721 {
    function safeMint(address to, uint256 id) external;

    function safeMintBatch(address to, uint256[] calldata ids) external;
}
