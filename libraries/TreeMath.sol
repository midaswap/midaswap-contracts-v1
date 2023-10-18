// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {BitMath} from "./BitMath.sol";

/**
 * @title Liquidity Book Tree Math Library
 * @notice This library contains functions to interact with a tree of TreeUint24.
 */
library TreeMath {
    using BitMath for uint256;

    struct TreeUint24 {
        bytes32 level0;
        mapping(bytes32 => bytes32) level1;
        mapping(bytes32 => bytes32) level2;
    }

    // /**
    //  * @dev Returns true if the tree contains the id
    //  * @param tree The tree
    //  * @param id The id
    //  * @return True if the tree contains the id
    //  */
    // function contains(TreeUint24 storage tree, uint24 id) internal view returns (bool) {
    //     bytes32 leaf2 = bytes32(uint256(id) >> 8);

    //     return tree.level2[leaf2] & bytes32(1 << (id & type(uint8).max)) != 0;
    // }

    /**
     * @dev Adds the id to the tree.
     * It will also propagate the change to the parent levels.
     * @param tree The tree
     * @param id The id
     */
    function add(TreeUint24 storage tree, uint24 id) internal {
        bytes32 key2 = bytes32(uint256(id) >> 8);

        bytes32 leaves = tree.level2[key2];
        bytes32 newLeaves = leaves | bytes32(1 << (id & type(uint8).max));

        if (leaves != newLeaves) {
            tree.level2[key2] = newLeaves;

            if (leaves == 0) {
                bytes32 key1 = key2 >> 8;
                leaves = tree.level1[key1];

                tree.level1[key1] =
                    leaves |
                    bytes32(1 << (uint256(key2) & type(uint8).max));

                if (leaves == 0)
                    tree.level0 |= bytes32(
                        1 << (uint256(key1) & type(uint8).max)
                    );
            }

            // return true;
        }

        // return false;
    }

    /**
     * @dev Removes the id from the tree.
     * It will also propagate the change to the parent levels.
     * @param tree The tree
     * @param id The id
     */
    function remove(TreeUint24 storage tree, uint24 id) internal {
        bytes32 key2 = bytes32(uint256(id) >> 8);

        bytes32 leaves = tree.level2[key2];
        bytes32 newLeaves = leaves & ~bytes32(1 << (id & type(uint8).max));

        if (leaves != newLeaves) {
            tree.level2[key2] = newLeaves;

            if (newLeaves == 0) {
                bytes32 key1 = key2 >> 8;
                leaves = tree.level1[key1];
                leaves &= ~bytes32(1 << (uint256(key2) & type(uint8).max));
                tree.level1[key1] = leaves;

                if (leaves == 0)
                    tree.level0 &= ~bytes32(
                        1 << (uint256(key1) & type(uint8).max)
                    );
            }

            // return true;
        }

        // return false;
    }

    /**
     * @dev Returns the first id in the tree that is strictly lower than the given id.
     * It will return type(uint24).max if there is no such id.
     * @param tree The tree
     * @param id The id
     * @return The first id in the tree that is lower than or equal to the given id
     */
    function findFirstRight(
        TreeUint24 storage tree,
        uint24 id
    ) internal view returns (uint24) {
        bytes32 leaves;

        bytes32 key2 = bytes32(uint256(id) >> 8);
        uint8 bit = uint8(id & type(uint8).max);

        if (bit != 0) {
            leaves = tree.level2[key2];
            uint256 closestBit = _closestBitRight(leaves, bit);

            if (closestBit != type(uint256).max)
                return uint24((uint256(key2) << 8) | closestBit);
        }

        bytes32 key1 = key2 >> 8;
        bit = uint8(uint256(key2) & type(uint8).max);

        if (bit != 0) {
            leaves = tree.level1[key1];
            uint256 closestBit = _closestBitRight(leaves, bit);

            if (closestBit != type(uint256).max) {
                key2 = bytes32((uint256(key1) << 8) | closestBit);
                leaves = tree.level2[key2];

                return
                    uint24(
                        (uint256(key2) << 8) |
                            uint256(leaves).mostSignificantBit()
                    );
            }
        }

        bit = uint8(uint256(key1) & type(uint8).max);

        if (bit != 0) {
            leaves = tree.level0;
            uint256 closestBit = _closestBitRight(leaves, bit);

            if (closestBit != type(uint256).max) {
                key1 = bytes32(closestBit);
                leaves = tree.level1[key1];

                key2 = bytes32(
                    (uint256(key1) << 8) | uint256(leaves).mostSignificantBit()
                );
                leaves = tree.level2[key2];

                return
                    uint24(
                        (uint256(key2) << 8) |
                            uint256(leaves).mostSignificantBit()
                    );
            }
        }

        return type(uint24).min;
    }

    /**
     * @dev Returns the first id in the tree that is strictly higher than the given id.
     * It will return 0 if there is no such id.
     * @param tree The tree
     * @param id The id
     * @return The first id in the tree that is higher than or equal to the given id
     */
    function findFirstLeft(
        TreeUint24 storage tree,
        uint24 id
    ) internal view returns (uint24) {
        bytes32 leaves;

        bytes32 key2 = bytes32(uint256(id) >> 8);
        uint8 bit = uint8(id & type(uint8).max);

        if (bit != type(uint8).max) {
            leaves = tree.level2[key2];
            uint256 closestBit = _closestBitLeft(leaves, bit);

            if (closestBit != type(uint256).max)
                return uint24((uint256(key2) << 8) | closestBit);
        }

        bytes32 key1 = key2 >> 8;
        bit = uint8(uint256(key2) & type(uint8).max);

        if (bit != type(uint8).max) {
            leaves = tree.level1[key1];
            uint256 closestBit = _closestBitLeft(leaves, bit);

            if (closestBit != type(uint256).max) {
                key2 = bytes32((uint256(key1) << 8) | closestBit);
                leaves = tree.level2[key2];

                return
                    uint24(
                        (uint256(key2) << 8) |
                            uint256(leaves).leastSignificantBit()
                    );
            }
        }

        bit = uint8(uint256(key1) & type(uint8).max);

        if (bit != type(uint8).max) {
            leaves = tree.level0;
            uint256 closestBit = _closestBitLeft(leaves, bit);

            if (closestBit != type(uint256).max) {
                key1 = bytes32(closestBit);
                leaves = tree.level1[key1];

                key2 = bytes32(
                    (uint256(key1) << 8) | uint256(leaves).leastSignificantBit()
                );
                leaves = tree.level2[key2];

                return
                    uint24(
                        (uint256(key2) << 8) |
                            uint256(leaves).leastSignificantBit()
                    );
            }
        }

        return type(uint24).max;
    }

    /**
     * @dev Returns the first bit in the given leaves that is strictly lower than the given bit.
     * It will return type(uint256).max if there is no such bit.
     * @param leaves The leaves
     * @param bit The bit
     * @return The first bit in the given leaves that is strictly lower than the given bit
     */
    function _closestBitRight(
        bytes32 leaves,
        uint8 bit
    ) private pure returns (uint256) {
        unchecked {
            return uint256(leaves).closestBitRight(bit - 1);
        }
    }

    /**
     * @dev Returns the first bit in the given leaves that is strictly higher than the given bit.
     * It will return type(uint256).max if there is no such bit.
     * @param leaves The leaves
     * @param bit The bit
     * @return The first bit in the given leaves that is strictly higher than the given bit
     */
    function _closestBitLeft(
        bytes32 leaves,
        uint8 bit
    ) private pure returns (uint256) {
        unchecked {
            return uint256(leaves).closestBitLeft(bit + 1);
        }
    }

    /**
     * @dev Returns floorPrice bin and bestOffer bin in given trees
     * @param _tree The tokenY tree
     * @param _tree2 The tokenX tree
     * @return _bin The bestOffer Bin
     * @return _bin2 The floorPrice Bin
     */
    function updateBins(
        TreeUint24 storage _tree,
        TreeUint24 storage _tree2
    ) internal view returns (uint24 _bin, uint24 _bin2) {
        _bin2 = findFirstLeft(_tree2, type(uint24).min);
        _bin = findFirstRight(
            _tree,
            _bin2 + (_bin2 == type(uint24).max ? type(uint24).min : 1)
        );
    }
}
