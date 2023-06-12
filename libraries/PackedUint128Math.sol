// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Packed Uint128 Math Library
 * @notice This library contains functions to encode and decode two uint128 into a single bytes32
 * and interact with the encoded bytes32.
 */
library PackedUint128Math {
    error PackedUint128Math__AddOverflow();
    error PackedUint128Math__SubUnderflow();
    error PackedUint128Math__MultiplierTooLarge();

    uint256 private constant OFFSET = 128;
    uint256 private constant MASK_128 = 0xffffffffffffffffffffffffffffffff;
    uint256 private constant MASK_128_PLUS_ONE = MASK_128 + 1;

    /**
     * @dev Encodes two uint128 into a single bytes32
     * @param x1 The first uint128
     * @param x2 The second uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     */
    function encode(uint128 x1, uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := or(and(x1, MASK_128), shl(OFFSET, x2))
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the first uint128
     * @param x1 The uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: empty
     */
    function encodeFirst(uint128 x1) internal pure returns (bytes32 z) {
        assembly {
            z := and(x1, MASK_128)
        }
    }

    // /**
    //  * @dev Encodes a uint128 into a single bytes32 as the second uint128
    //  * @param x2 The uint128
    //  * @return z The encoded bytes32 as follows:
    //  * [0 - 128[: empty
    //  * [128 - 256[: x2
    //  */
    // function encodeSecond(uint128 x2) internal pure returns (bytes32 z) {
    //     assembly {
    //         z := shl(OFFSET, x2)
    //     }
    // }

    // /**
    //  * @dev Encodes a uint128 into a single bytes32 as the first or second uint128
    //  * @param x The uint128
    //  * @param first Whether to encode as the first or second uint128
    //  * @return z The encoded bytes32 as follows:
    //  * if first:
    //  * [0 - 128[: x
    //  * [128 - 256[: empty
    //  * else:
    //  * [0 - 128[: empty
    //  * [128 - 256[: x
    //  */
    // function encode(uint128 x, bool first) internal pure returns (bytes32 z) {
    //     return first ? encodeFirst(x) : encodeSecond(x);
    // }

    /**
     * @dev Decodes a bytes32 into two uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return x1 The first uint128
     * @return x2 The second uint128
     */
    function decode(bytes32 z) internal pure returns (uint128 x1, uint128 x2) {
        assembly {
            x1 := and(z, MASK_128)
            x2 := shr(OFFSET, z)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the first uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: x
     * [128 - 256[: any
     * @return x The first uint128
     */
    function decodeX(bytes32 z) internal pure returns (uint128 x) {
        assembly {
            x := and(z, MASK_128)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the second uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: any
     * [128 - 256[: y
     * @return y The second uint128
     */
    function decodeY(bytes32 z) internal pure returns (uint128 y) {
        assembly {
            y := shr(OFFSET, z)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the first or second uint128
     * @param z The encoded bytes32 as follows:
     * if first:
     * [0 - 128[: x1
     * [128 - 256[: empty
     * else:
     * [0 - 128[: empty
     * [128 - 256[: x2
     * @param first Whether to decode as the first or second uint128
     * @return x The decoded uint128
     */
    function decode(bytes32 z, bool first) internal pure returns (uint128 x) {
        return first ? decodeX(z) : decodeY(z);
    }

    /**
     * @dev Adds two encoded bytes32, reverting on overflow on any of the uint128
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return z The sum of x and y encoded as follows:
     * [0 - 128[: x1 + y1
     * [128 - 256[: x2 + y2
     */
    function add(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := add(x, y)
        }

        checkAddOverFlow(z, x);
    }

    /**
     * @dev Adds an encoded bytes32 and two uint128, reverting on overflow on any of the uint128
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y1 The first uint128
     * @param y2 The second uint128
     * @return z The sum of x and y encoded as follows:
     * [0 - 128[: x1 + y1
     * [128 - 256[: x2 + y2
     */
    function add(
        bytes32 x,
        uint128 y1,
        uint128 y2
    ) internal pure returns (bytes32) {
        return add(x, encode(y1, y2));
    }

    /**
     * @dev Subtracts two encoded bytes32, reverting on underflow on any of the uint128
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return z The difference of x and y encoded as follows:
     * [0 - 128[: x1 - y1
     * [128 - 256[: x2 - y2
     */
    function sub(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := sub(x, y)
        }

        checkSubOverFlow(z, x);
    }

    /**
     * @dev Subtracts an encoded bytes32 and two uint128, reverting on underflow on any of the uint128
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y1 The first uint128
     * @param y2 The second uint128
     * @return z The difference of x and y encoded as follows:
     * [0 - 128[: x1 - y1
     * [128 - 256[: x2 - y2
     */
    function sub(
        bytes32 x,
        uint128 y1,
        uint128 y2
    ) internal pure returns (bytes32) {
        return sub(x, encode(y1, y2));
    }

    // /**
    //  * @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
    //  * @param x The first bytes32 encoded as follows:
    //  * [0 - 128[: x1
    //  * [128 - 256[: x2
    //  * @param y The second bytes32 encoded as follows:
    //  * [0 - 128[: y1
    //  * [128 - 256[: y2
    //  * @return x1 < y1 || x2 < y2
    //  */
    // function lt(bytes32 x, bytes32 y) internal pure returns (bool) {
    //     (uint128 x1, uint128 x2) = decode(x);
    //     (uint128 y1, uint128 y2) = decode(y);

    //     return x1 < y1 || x2 < y2;
    // }

    // /**
    //  * @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
    //  * @param x The first bytes32 encoded as follows:
    //  * [0 - 128[: x1
    //  * [128 - 256[: x2
    //  * @param y The second bytes32 encoded as follows:
    //  * [0 - 128[: y1
    //  * [128 - 256[: y2
    //  * @return x1 < y1 || x2 < y2
    //  */
    // function gt(bytes32 x, bytes32 y) internal pure returns (bool) {
    //     (uint128 x1, uint128 x2) = decode(x);
    //     (uint128 y1, uint128 y2) = decode(y);

    //     return x1 > y1 || x2 > y2;
    // }

    // /**
    //  * @dev Multiplies an encoded bytes32 by a uint128 then divides the result by 10_000, rounding down
    //  * The result can't overflow as the multiplier needs to be smaller or equal to 10_000
    //  * @param x The bytes32 encoded as follows:
    //  * [0 - 128[: x1
    //  * [128 - 256[: x2
    //  * @param multiplier The uint128 to multiply by (must be smaller or equal to 10_000)
    //  * @return z The product of x and multiplier encoded as follows:
    //  * [0 - 128[: floor((x1 * multiplier) / 10_000)
    //  * [128 - 256[: floor((x2 * multiplier) / 10_000)
    //  */
    // function scalarMulDivBasisPointRoundDown(bytes32 x, uint128 multiplier) internal pure returns (bytes32 z) {
    //     if (multiplier == 0) return 0;

    //     uint256 BASIS_POINT_MAX = Constants.BASIS_POINT_MAX;
    //     if (multiplier > BASIS_POINT_MAX) revert PackedUint128Math__MultiplierTooLarge();

    //     (uint128 x1, uint128 x2) = decode(x);

    //     assembly {
    //         x1 := div(mul(x1, multiplier), BASIS_POINT_MAX)
    //         x2 := div(mul(x2, multiplier), BASIS_POINT_MAX)
    //     }

    //     return encode(x1, x2);
    // }


    /**
     * @dev Adds an encoded bytes32 and one uint128, reverting on overflow on the uint128
     * @param a The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param b The first uint128
     * @return z The sum of a and b encoded as follows:
     * [0 - 128[: x1 + b
     * [128 - 256[: x2
     */
    function addFirst(bytes32 a, uint128 b) internal pure returns (bytes32 z) {
        assembly {
            z := add(a, and(b, 0xffffffffffffffffffffffffffffffff))
        }
        checkAddOverFlow(z, a);
    }

    /**
     * @dev Adds an encoded bytes32 and one uint128, reverting on overflow on the uint128
     * @param a The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param b The second uint128
     * @return z The sum of a and b encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2 + b
     */
    function addSecond(bytes32 a, uint128 b) internal pure returns (bytes32 z) {
        assembly {
            z := add(a, shl(128, b))
        }
        checkAddOverFlow(z, a);
    }

    /**
     * @dev Subtracts an encoded bytes32 by one uint128, reverting on overflow on the uint128
     * @param a The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param b The first uint128
     * @return z The diff of a and b encoded as follows:
     * [0 - 128[: x1 - b
     * [128 - 256[: x2
     */
    function subFirst(bytes32 a, uint128 b) internal pure returns (bytes32 z) {
        assembly {
            z := sub(a, and(b, 0xffffffffffffffffffffffffffffffff))
        }

        checkSubOverFlow(z, a);
    }
    
    /**
     * @dev Subtracts an encoded bytes32 by one uint128, reverting on overflow on the uint128
     * @param a The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param b The second uint128
     * @return z The diff of a and b encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2 - b
     */
    function subSecond(bytes32 a, uint128 b) internal pure returns (bytes32 z) {
        assembly {
            z := sub(a, shl(128, b))
        }

        checkSubOverFlow(z, a);
    }

    /**
     * @dev Encodes a bytes32 and a uint128 into a single bytes32
     * @param oldParams The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param param The uint128
     * @return newParams The encoded bytes32 as follows:
     * [0 - 128[: param
     * [128 - 256[: x2
     */
    function setFirst(
        bytes32 oldParams,
        uint128 param
    ) internal pure returns (bytes32 newParams) {
        assembly {
            newParams := and(oldParams, not(0xffffffffffffffffffffffffffffffff))
            newParams := or(
                newParams,
                and(param, 0xffffffffffffffffffffffffffffffff)
            )
        }
    }

    /**
     * @dev Encodes a bytes32 and a uint128 into a single bytes32
     * @param oldParams The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param param The uint128
     * @return newParams The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: param
     */
    function setSecond(
        bytes32 oldParams,
        uint128 param
    ) internal pure returns (bytes32 newParams) {
        assembly {
            newParams := and(
                oldParams,
                not(shl(128, 0xffffffffffffffffffffffffffffffff))
            )
            newParams := or(
                newParams,
                shl(128, and(param, 0xffffffffffffffffffffffffffffffff))
            )
        }
    }

    /** 
     * Checks overflow in bytes32 add
     * @param z The bytes32 after add
     * @param a The bytes32 before add
     */
    function checkAddOverFlow(bytes32 z, bytes32 a) internal pure {
        if (z < a || uint128(uint256(z)) < uint128(uint256(a))) {
            revert PackedUint128Math__AddOverflow();
        }
    }

    /** 
     * Checks overflow in bytes32 sub
     * @param z The bytes32 after sub
     * @param a The bytes32 before sub
     */
    function checkSubOverFlow(bytes32 z, bytes32 a) internal pure {
        if (z > a || uint128(uint256(z)) > uint128(uint256(a))) {
            revert PackedUint128Math__SubUnderflow();
        }
    }
}
