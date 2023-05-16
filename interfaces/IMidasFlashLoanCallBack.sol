// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Midas Flashloan Callback Interface
/// @author Midas
/// @notice Required interface to interact with Midas flash loans
interface IMidasFlashLoanCallback {
    function MidasFlashLoanCallback(
        IERC721 tokenX,
        uint256[] calldata NFTlist,
        bytes calldata data
    ) external returns (bytes32);
}