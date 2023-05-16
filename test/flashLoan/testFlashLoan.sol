// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IMidasPair721} from "./MidasPair721.sol";

import {IMidasFlashLoanCallback} from "./interfaces/IMidasFlashLoanCallback.sol";



contract Test {
    IMidasPair721 public pair;
    IMidasFlashLoanCallback public receiver;
    constructor(IMidasPair721 Pair , IMidasFlashLoanCallback Receiver){
        pair = Pair;
        receiver = Receiver;
    }

    function test(uint256[] calldata _tokenIds) external {
        bytes memory xx;
        xx = abi.encode(uint256(0));
        pair.flashLoan(receiver, _tokenIds, xx);
    }
    
}