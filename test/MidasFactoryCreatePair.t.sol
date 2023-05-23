// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IMidasFactory721} from "../interfaces/IMidasFactory721.sol";

contract MidasFactoryCreatePairTest {

    IMidasFactory721 public factory;

    constructor (address _factory) {
        factory = IMidasFactory721(_factory);
    }
    
    function createPairWithValidAddress(
        address _token0,
        address _token1
    ) external returns (address lpToken, address pair) {
        (lpToken, pair) = factory.createERC721Pair(_token0, _token1);
    }

    function createPairTwice(
        address _token0,
        address _token1
    ) external returns (address lpToken, address pair) {
        (lpToken, pair) = factory.createERC721Pair(_token0, _token1);
        (lpToken, pair) = factory.createERC721Pair(_token0, _token1);
    }
    
}
