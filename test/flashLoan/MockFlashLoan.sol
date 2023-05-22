// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import {IMidasPair721} from "./MidasPair721.sol";
import {IMidasFlashLoanCallback} from "./interfaces/IMidasFlashLoanCallback.sol";



contract FlashBorrower is IMidasFlashLoanCallback , ERC721Holder {

    IMidasPair721 public pair;
    uint256 public x;
    constructor(IMidasPair721 Pair){
        pair = Pair;
    }
    
    function MidasFlashLoanCallback(
        IERC721 tokenX,
        uint256[] calldata _tokenIds,
        bytes calldata data
    ) external override returns (bytes32) {
        bytes32 callback;
        callback = abi.decode(data, (bytes32));
        for(uint i; i < _tokenIds.length ; ++i){
            tokenX.safeTransferFrom(
                        address(this),
                        address(pair),
                        _tokenIds[i]
                );
        }
        x = 1;
        return callback;
    }
}
