// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

/**
 * @title PositionHelper Library
 * @notice This library contains functions to interact with a tree of TreeUint24.
 */
library PositionHelper {
    /**
     * @dev Checks whether the given array is Arithmetic progression
     * @dev Returns the common difference if it is Arithmetic progression
     * @param arr The given array
     * @return originBin The first item
     * @return commonDiff The common difference
     */
    function _checkBinSequence(
        uint24[] calldata arr
    ) internal pure returns (uint24 originBin, uint24 commonDiff) {
        uint256 length;
        length = arr.length;
        originBin = arr[0];
        if (length > 1) {
            uint24 target = arr[1];
            commonDiff = target - originBin;
            for (uint256 i = 2; i < length; ) {
                target += commonDiff;
                if (arr[i] != target) revert MidasPair__BinSequenceWrong();
                unchecked {
                    ++i;
                }
            }
        }
    }

    error MidasPair__BinSequenceWrong();

    /**
     * @dev Removes the first given item of the given array and returns it
     * @param arr The given array
     * @return arr The returned array
     */
    function _findIndexAndRemove(
        uint128[] memory arr,
        uint128 target
    ) internal pure returns (uint128[] memory) {
        assembly {
            let length := mload(arr)
            let guard := mul(length, 0x20)
            for {
                let offset := 0x20
            } lt(offset, guard) {
                offset := add(offset, 0x20)
            } {
                if eq(mload(add(arr, offset)), target) {
                    mstore(add(arr, offset), mload(add(arr, guard)))
                    break
                }
            }
            mstore(arr, sub(length, 1))
        }

        return arr;
    }
}
