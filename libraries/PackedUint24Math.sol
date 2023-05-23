// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Packed Uint128 Math Library
 * @notice This library contains functions to encode and decode two uint128 into a single bytes32
 * and interact with the encoded bytes32.
 */
library PackedUint24Math {
    error PackedUint24Math__AddOverflow();

    /**
     * @dev Decodes a bytes32 into a uint24 as the first uint24
     * @param params The encoded bytes32 as follows:
     * [0 - 24[: baseFactor
     * [24 - 48[: any
     * [48 - 176[: any
     * @return baseFactor The first uint24
     */
    function getFirstUint24(
        bytes32 params
    ) internal pure returns (uint24 baseFactor) {
        assembly {
            baseFactor := and(params, 0xffffff)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint24 as the second uint24
     * @param params The encoded bytes32 as follows:
     * [0 - 24[: any
     * [24 - 48[: baseFactor
     * [48 - 176[: any
     * @return baseFactor The second uint24
     */
    function getSecondUint24(
        bytes32 params
    ) internal pure returns (uint24 baseFactor) {
        assembly {
            baseFactor := and(shr(24, params), 0xffffff)
        }
    }

    /**
     * @dev Decodes a bytes32 into two uint24
     * @param params The encoded bytes32 as follows:
     * [0 - 24[: baseFactorA
     * [24 - 48[: baseFactorB
     * [48 - 176[: any
     * @return baseFactorA The second uint24
     * @return baseFactorB The second uint24
     */
    function getBothUint24(
        bytes32 params
    ) internal pure returns (uint24 baseFactorA, uint24 baseFactorB) {
        assembly {
            baseFactorA := and(params, 0xffffff)
            baseFactorB := and(shr(24, params), 0xffffff)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128
     * @param params The encoded bytes32 as follows:
     * [0 - 24[: any
     * [24 - 48[: any
     * [48 - 176[: baseFactor
     * @return baseFactor The uint128
     */
    function getUint128(
        bytes32 params
    ) internal pure returns (uint128 baseFactor) {
        assembly {
            baseFactor := and(
                shr(48, params),
                0xffffffffffffffffffffffffffffffff
            )
        }
    }

    /**
     * @dev Decodes a bytes32 into two uint24 and one uint128
     * @param params The encoded bytes32 as follows:
     * [0 - 24[: baseFactorA
     * [24 - 48[: baseFactorB
     * [48 - 176[: baseFactorC
     * @return baseFactorA The second uint24
     * @return baseFactorB The second uint24
     * @return baseFactorC The second uint128
     */
    function getAll(
        bytes32 params
    )
        internal
        pure
        returns (uint24 baseFactorA, uint24 baseFactorB, uint128 baseFactorC)
    {
        assembly {
            baseFactorA := and(params, 0xffffff)
            baseFactorB := and(shr(24, params), 0xffffff)
            baseFactorC := and(
                shr(48, params),
                0xffffffffffffffffffffffffffffffff
            )
        }
    }

    /**
     * @dev Encodes a bytes32 and two uint24 into a single bytes32
     * @param oldParams The bytes32 encoded as follows:
     * [0 - 24[: baseFactorA
     * [24 - 48[: baseFactorB
     * [48 - 176[: baseFactorC
     * @param paramA The first uint24 to be set
     * @param paramB The second uint24 to be set
     * @return newParams The encoded bytes32 as follows:
     * [0 - 24[: paramA
     * [24 - 48[: paramB
     * [48 - 176[: baseFactorC
     */
    function setBothUint24(
        bytes32 oldParams,
        uint24 paramA,
        uint24 paramB
    ) internal pure returns (bytes32 newParams) {
        assembly {
            newParams := and(oldParams, not(shl(0, 0xffffff)))
            newParams := or(newParams, shl(0, and(paramA, 0xffffff)))
            newParams := and(newParams, not(shl(24, 0xffffff)))
            newParams := or(newParams, shl(24, and(paramB, 0xffffff)))
        }
    }

    /**
     * @dev Encodes a bytes32 and a uint128 into a single bytes32
     * @param oldParams The bytes32 encoded as follows:
     * [0 - 24[: baseFactorA
     * [24 - 48[: baseFactorB
     * [48 - 176[: baseFactorC
     * @param param The uint128 to be set
     * @return newParams The encoded bytes32 as follows:
     * [0 - 24[: baseFactorA
     * [24 - 48[: baseFactorB
     * [48 - 176[: param
     */
    function setUint128(
        bytes32 oldParams,
        uint128 param
    ) internal pure returns (bytes32 newParams) {
        assembly {
            newParams := and(
                oldParams,
                not(shl(48, 0xffffffffffffffffffffffffffffffff))
            )
            newParams := or(
                newParams,
                shl(48, and(param, 0xffffffffffffffffffffffffffffffff))
            )
        }
    }

    /**
     * @dev Encodes two uint24 and a uint128 into a single bytes32
     * @param paramA The first uint24 to be set
     * @param paramB The second uint24 to be set
     * @param paramC The uint128 to be set
     * @return newParams The encoded bytes32 as follows:
     * [0 - 24[: paramA
     * [24 - 48[: paramB
     * [48 - 176[: paramC
     */
    function setAll(
        uint24 paramA,
        uint24 paramB,
        uint128 paramC
    ) internal pure returns (bytes32 newParams) {
        assembly {
            newParams := shl(48, paramC)
            newParams := or(shl(24, paramB), newParams)
            newParams := or(paramA, newParams)
        }
    }

    /**
     * @dev Adds an encoded bytes32 and one uint128, reverting on overflow on the uint128
     * @param oldParams The bytes32 encoded as follows:
     * [0 - 24[: baseFactorA
     * [24 - 48[: baseFactorB
     * [48 - 176[: baseFactorC
     * @param param The  uint128
     * @return newParams The sum of oldParams and param encoded as follows:
     * [0 - 24[: baseFactorA
     * [24 - 48[: baseFactorB
     * [48 - 176[: baseFactorC + param
     */
    function addUint128(
        bytes32 oldParams,
        uint128 param
    ) internal pure returns (bytes32 newParams) {
        assembly {
            newParams := add(oldParams, shl(48, param))
        }
        if (newParams < oldParams) {
            revert PackedUint24Math__AddOverflow();
        }
    }
}
