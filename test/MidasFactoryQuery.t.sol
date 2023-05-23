// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IMidasFactory721} from "../interfaces/IMidasFactory721.sol";

contract MidasFactoryQueryTest {
    
    IMidasFactory721 public factory;

    constructor (address _factory) {
        factory = IMidasFactory721(_factory);
    }

    function getPairAndLptAddress(
        address _token0,
        address _token1
    ) external view returns(address pair, address lpToken) {
        pair = factory.getPairERC721(_token0, _token1);
        lpToken = factory.getLPTokenERC721(_token0, _token1);
    }

}