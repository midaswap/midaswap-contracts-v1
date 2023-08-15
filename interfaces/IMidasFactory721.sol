// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Midas Factory Interface
// @author Midas
/// @notice Required interface to interact with Midas Factory
interface IMidasFactory721 {

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event PairImplementationSet(
        address indexed oldPair,
        address indexed newPair
    );

    event LptImplementationSet(address indexed oldLPT, address indexed newLPT);

    event PairCreated(
        address indexed tokenX,
        address indexed tokenY,
        address indexed pair,
        address lpToken
    );

    function createERC721Pair(
        address _tokenX,
        address _tokenY
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

    function setOwner(address _owner) external;

    function setRoyaltyInfo(address _tokenX, address _tokenY, bool isZero) external;

    function setPairImplementation(address _newPairImplementation) external;

    function setLptImplementation(address _newLptImplementation) external;

}
