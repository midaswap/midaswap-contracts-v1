// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Packed Uint128 Math Library
 * @notice This library contains functions to encode and decode two uint128 into a single bytes32
 * and interact with the encoded bytes32.
 */
library PackedUint24Math {
    error PackedUint24Math__AddOverflow();

    function getFirstUint24(
        bytes32 params
    ) internal pure returns (uint24 baseFactor) {
        assembly {
            baseFactor := and(params, 0xffffff)
        }
    }

    function getSecondUint24(
        bytes32 params
    ) internal pure returns (uint24 baseFactor) {
        assembly {
            baseFactor := and(shr(24, params), 0xffffff)
        }
    }

    function getBothUint24(
        bytes32 params
    ) internal pure returns (uint24 baseFactorA, uint24 baseFactorB) {
        assembly {
            baseFactorA := and(params, 0xffffff)
            baseFactorB := and(shr(24, params), 0xffffff)
        }
    }

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
