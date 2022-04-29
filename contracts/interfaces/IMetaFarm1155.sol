//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMetaFarm1155 is IERC1155 {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;
}
