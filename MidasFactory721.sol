// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./LPToken.sol";
import "./MidasPair721.sol";
import "./NoDelegateCall.sol";
import "./MidasPairDeployer.sol";

import "./interfaces/IMidasPair721.sol";
import "./interfaces/IMidasFactory721.sol";
import "./interfaces/IRoyaltyEngineV1.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title Midas Pair Factory
/// @author midaswap
/// @notice Deploys Midaswap pairs and manages ownership

contract MidasFactory721 is IMidasFactory721, NoDelegateCall {
    address private owner;
    uint128 private feeEnabled;
    uint128 private royaltyRate;

    PairDeployer private pairDeployer;
    IRoyaltyEngineV1 private royaltyEngine;

    mapping(address => mapping(address => address))
        public
        override getPairERC721;
    mapping(address => mapping(address => address))
        public
        override getLPTokenERC721;

    constructor(
        uint128 _feeRate,
        uint128 _royaltyRate,
        address _royaltyEngine,
        address _deployer
    ) {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeEnabled = _feeRate;
        emit FeeRateChanged(uint128(0), feeEnabled);

        royaltyRate = _royaltyRate;
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);

        pairDeployer = PairDeployer(_deployer);
    }

    function feeRecipient() external view returns (address _feeRecipient) {
        _feeRecipient = owner;
    }

    /// @dev The function to create ERC721-ERC20 pair and the nonfungible lp Token contract
    /// @param _token0  The first input token address
    /// @param _token1  The second input token address
    /// @return lpToken The address of lpToken
    /// @return pair    The address of Midas pair
    function createERC721Pair(
        address _token0,
        address _token1
    ) external override noDelegateCall returns (address lpToken, address pair) {
        require(_token0 != _token1 && _token1 != address(0));
        require(IERC721(_token0).supportsInterface(bytes4(0x80ac58cd)));
        require(getPairERC721[_token0][_token1] == address(0));
        (lpToken, pair) = pairDeployer.deployERC721(
            _token0,
            _token1,
            feeEnabled
        );
        (
            address payable[] memory _recipients,
            uint256[] memory _shares
        ) = royaltyEngine.getRoyaltyView(_token0, 1, 1e18);
        if (_shares.length > 0) {
            uint256 _shareSum;
            for (uint256 i = 0; i < _shares.length; ++i) {
                _shareSum += _shares[i];
            }
            for (uint256 i = 0; i < _shares.length; ++i) {
                _shares[i] = (_shares[i] * 1e18) / _shareSum - 1;
            }
            IMidasPair721(pair).updateRoyalty(
                royaltyRate,
                _recipients,
                _shares
            );
        } else {
            IMidasPair721(pair).updateRoyalty(uint128(0), _recipients, _shares);
        }

        LPToken(lpToken).initialize(pair);
        getPairERC721[_token0][_token1] = pair;
        getLPTokenERC721[_token0][_token1] = lpToken;

        emit PairCreated(_token0, _token1, feeEnabled, pair, lpToken);
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @dev The function to change the royalty rate of specific rate
    /// @param _nftAddress  The address of NFT asset
    /// @param _pair        The address of Midas pair
    /// @param _newRate     The new royalty rate
    function setRoyaltyInfo(
        address _nftAddress,
        address _pair,
        uint128 _newRate
    ) external {
        require(msg.sender == owner);
        royaltyRate = _newRate;
        (
            address payable[] memory _recipients,
            uint256[] memory _shares
        ) = royaltyEngine.getRoyaltyView(_nftAddress, 1, 1e18);

        if (_shares.length > 0) {
            uint256 _shareSum;
            for (uint256 i = 0; i < _shares.length; ++i) {
                _shareSum += _shares[i];
            }
            for (uint256 i = 0; i < _shares.length; ++i) {
                _shares[i] = (_shares[i] * 1e18) / _shareSum - 1;
            }
            IMidasPair721(_pair).updateRoyalty(
                royaltyRate,
                _recipients,
                _shares
            );
        } else {
            IMidasPair721(_pair).updateRoyalty(
                uint128(0),
                _recipients,
                _shares
            );
        }
    }
}
