// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library PositionHelper {
    error MidasPair__BinSequenceWrong();

    function _checkBinSequence(
        uint24[] calldata _binIds
    ) internal pure returns (uint24 commonDiff) {
        uint256 length;
        length = _binIds.length;
        if (length > 1) {
            uint24 target = _binIds[1];
            commonDiff = target - _binIds[0];
            for (uint256 i = 2; i < length; ) {
                target += commonDiff;
                if (_binIds[i] != target) revert MidasPair__BinSequenceWrong();
                unchecked {
                    ++i;
                }
            }
        }
    }

    function _removeFirstItem(
        uint128[] memory arr
    ) internal pure returns (uint128[] memory) {
        uint256 length;
        uint128[] memory newArr;
        // arr must have length of at least 1, otherwise this function should not be called
        unchecked {
            length = arr.length - 1;
        }
        newArr = new uint128[](length);
        for (uint256 i; i < length; ) {
            newArr[i] = arr[i + 1];
            unchecked {
                ++i;
            }
        }
        return newArr;
    }

    function _findIndexAndRemove(
        uint128[] memory arr,
        uint128 target
    ) internal pure returns (uint128[] memory) {
        uint256 j;
        uint256 _length;
        uint128[] memory newArr;
        // arr must have length of at least 1, otherwise this function should not be called
        unchecked {
            _length = arr.length - 1;
        }
        newArr = new uint128[](_length);
        for (uint256 i; i < _length; ) {
            if (arr[i] == target) j = 1;
            unchecked {
                newArr[i] = arr[i + j];
                ++i;
            }
        }
        return newArr;
    }
}
