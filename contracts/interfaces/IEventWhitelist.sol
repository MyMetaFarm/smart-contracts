//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IEventWhitelist {
    function isInWhitelist(address _user) external view returns (bool);
}
