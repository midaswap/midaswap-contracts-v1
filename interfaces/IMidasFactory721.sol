// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IMidasFactory721 {

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event FeeRateChanged(uint128 indexed oldFee, uint128 indexed newFee);

    event PairImplementationSet(address indexed oldPair, address indexed newPair);

    event LptImplementationSet(address indexed oldLPT, address indexed newLPT);

    event PairCreated(
        address indexed tokenX,
        address indexed tokenY,
        uint256 indexed feeRate,
        address pair,
        address lpToken
    );

    function createERC721Pair(
        address _token0,
        address _token1
    ) external returns (address lpToken, address pair);

    function feeRecipient() external view returns (address _feeRecipient);

    function getPairERC721(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function getLPTokenERC721(
        address tokenA,
        address tokenB
    ) external view returns (address lpToken);
 
    function setRoyaltyInfo(
        address _nftAddress,
        address _pair
    ) external;

}
