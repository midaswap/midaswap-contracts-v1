// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library PositionHelper {
    // error MidasPair__BinSequenceWrong();

    // function _checkBinSequence(
    //     uint24[] calldata _binIds
    // ) internal pure returns (uint24 commonDiff) {
    //     uint256 length;
    //     length = _binIds.length;
    //     if (length > 1) {
    //         uint24 target = _binIds[1];
    //         commonDiff = target - _binIds[0];
    //         for (uint256 i = 2; i < length; ) {
    //             target += commonDiff;
    //             if (_binIds[i] != target) revert MidasPair__BinSequenceWrong();
    //             unchecked {
    //                 ++i;
    //             }
    //         }
    //     }
    // }

    function _checkBinSequence(uint24[] calldata ns) internal pure returns (uint24 commonDiff) {
        assembly {
            if gt(ns.length, 1){
                let guard := calldatasize()
                let target := calldataload(add(ns.offset,32))
                commonDiff := sub(calldataload(add(ns.offset,32)), calldataload(ns.offset))
                if lt(calldataload(add(ns.offset,32)), calldataload(ns.offset)) {
                            revert(0, 0)
                        }
                for {let offset := add(ns.offset,64)} 
                    lt(offset, guard) 
                    {} 

                    {   
                        if lt(calldataload(offset), target) {
                            revert(0, 0)
                        }
                        target := add(target, commonDiff)
                        if iszero(eq(calldataload(offset), target)) {
                            revert(0, 0)                       
                        }
                        offset := add(offset, 32)
                
                    }
            }
        }
    }

    // function _removeFirstItem(
    //     uint128[] memory arr
    // ) internal pure returns (uint128[] memory) {
    //     uint256 length;
    //     uint128[] memory newArr;
    //     // arr must have length of at least 1, otherwise this function should not be called
    //     unchecked {
    //         length = arr.length - 1;
    //     }
    //     newArr = new uint128[](length);
    //     for (uint256 i; i < length; ) {
    //         newArr[i] = arr[i + 1];
    //         unchecked {
    //             ++i;
    //         }
    //     }
    //     return newArr;
    // }

    function _removeFirstItem(uint128[] memory arr) internal pure returns (uint128[] memory) {
        assembly {
            let length := mload(arr)
            let guard := mul(length, 0x20)
            for {
                let offset := 0x20
            } lt(offset, guard) {
                offset := add(offset, 0x20)
            } {
                mstore(add(arr, offset), mload(add(arr, add(offset, 0x20))))
            }
            mstore(arr, sub(length, 1))
        }
            
        return arr;
    }

    // function _findIndexAndRemove(
    //     uint128[] memory arr,
    //     uint128 target
    // ) internal pure returns (uint128[] memory) {
    //     uint256 j;
    //     uint256 _length;
    //     uint128[] memory newArr;
    //     // arr must have length of at least 1, otherwise this function should not be called
    //     unchecked {
    //         _length = arr.length - 1;
    //     }
    //     newArr = new uint128[](_length);
    //     for (uint256 i; i < _length; ) {
    //         if (arr[i] == target) j = 1;   
    //         unchecked {
    //             newArr[i] = arr[i + j];
    //             ++i;
    //         }
    //     }
    //     return newArr;
    // }


    function _findIndexAndRemove(
        uint128[] memory arr,
        uint128 target
    ) internal pure returns (uint128[] memory) {
        assembly {
            let length := mload(arr)
            let guard := mul(length, 0x20)
            let j
            for {
                let offset := 0x20
            } lt(offset, guard) {
                offset := add(offset, 0x20)
            } { 
                if eq(mload(add(arr, offset)), target) {
                    j := 0x20
                }
                mstore(add(arr, offset), mload(add(arr, add(offset, j))))
            }
            mstore(arr, sub(length, 1))
        }
            
        return arr;
    }
}
