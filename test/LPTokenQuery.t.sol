// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {LPToken} from "../LPToken.sol";

contract LPTokenQueryTest {

    function getTokenURI(
        address lpToken,
        uint128 lpTokenId
    ) external view virtual returns (string memory) {
        return LPToken(lpToken).tokenURI(lpTokenId);
    }

    function getLpReserves(
        address lpToken,
        uint128 lpTokenId
    ) external view virtual returns (uint128 xReserves, uint128 yReserves) {
        (xReserves, yReserves) = LPToken(lpToken).getReserves(lpTokenId);
    }

    function getBatchLpReserves(
        address lpToken,
        uint128[] calldata lpTokenId
    ) external view virtual returns (uint128[] memory xReserves, uint128[] memory yReserves) {
        xReserves = new uint128[](lpTokenId.length);
        yReserves = new uint128[](lpTokenId.length);
        for (uint256 i; i < lpTokenId.length; ) {
            (xReserves[i], yReserves[i]) = LPToken(lpToken).getReserves(lpTokenId[i]);
            unchecked {
                ++i;
            }
        }
    }
    
}
