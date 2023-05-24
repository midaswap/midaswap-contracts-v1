// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library PositionHelper {

    /**
     * @dev Checks whether the given array is Arithmetic progression 
     * @dev Returns the common difference if it is Arithmetic progression 
     * @param arr The given array
     * @return originBin The first item
     * @return commonDiff The common difference
     */
    function _checkBinSequence(uint24[] calldata arr) internal pure returns (uint24 originBin, uint24 commonDiff) {
        assembly {
            originBin := calldataload(arr.offset)
            if gt(arr.length, 1){
                let guard := calldatasize()
                let target := calldataload(add(arr.offset, 0x20))
                commonDiff := sub(calldataload(add(arr.offset, 0x20)), originBin)
                if lt(calldataload(add(arr.offset, 0x20)), originBin) {
                            revert(0, 0)
                        }
                for {let offset := add(arr.offset, 0x40)} 
                    lt(offset, guard) 
                    {offset := add(offset, 0x20)} 

                    {   
                        if lt(calldataload(offset), target) {
                            revert(0, 0)
                        }
                        target := add(target, commonDiff)
                        if iszero(eq(calldataload(offset), target)) {
                            revert(0, 0)                       
                        }
                
                    }
            }
        }
    }

    /**
     * @dev Removes the first item of the given array and returns it
     * @param arr The given array
     * @return arr The returned array
     */
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
