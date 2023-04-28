// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./MidasPair721.sol";

/// @title Midas Pair Deployer
/// @author midaswap
/// @notice Tool contract to deploy the pair and lp Token contracts

contract PairDeployer {
    address private owner;

    address private factory;

    constructor() {
        owner = msg.sender;
    }

    function initialize(address _factory) external {
        require(msg.sender == owner);
        factory = _factory;
    }

    function deployERC721(
        address _token0,
        address _token1,
        uint128 _feeRate
    ) external returns (address _lpToken, address _pair) {
        require(msg.sender == factory);
        _lpToken = address(
            new LPToken{salt: keccak256(abi.encode(_token0, _token1))}(
                "MidasLPToken",
                "MLPT",
                factory
            )
        );
        _pair = address(
            new MidasPair721{salt: keccak256(abi.encode(_token0, _token1))}(
                factory,
                _token0,
                _token1,
                _lpToken,
                _feeRate
            )
        );
    }
}
