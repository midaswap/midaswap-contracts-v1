// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Midas
/// @author midaswap
/// @notice Set of constants for Midas contracts
library Constants {
    uint256 internal constant SCALE_OFFSET = 128;
    uint256 internal constant SCALE = 1 << SCALE_OFFSET;
    uint256 internal constant BASIS_POINT_MAX = 10_000;
    int256 internal constant REAL_ID_SHIFT = 1 << 23;
    uint256 internal constant Bin_Step_Value = SCALE + SCALE / BASIS_POINT_MAX;
}
