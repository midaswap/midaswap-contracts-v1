// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {LPToken} from "./LPToken.sol";
import {NoDelegateCall} from "./NoDelegateCall.sol";

import {IMidasPair721} from "./interfaces/IMidasPair721.sol";
import {IMidasFactory721} from "./interfaces/IMidasFactory721.sol";
import {IRoyaltyEngineV1} from "./interfaces/IRoyaltyEngineV1.sol";
import {ImmutableClone} from "./libraries/ImmutableClone.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title Midas Pair Factory
/// @author midaswap
/// @notice Deploys Midaswap pairs and manages ownership

contract MidasFactory721 is IMidasFactory721, NoDelegateCall {

    address private owner;
    address private pairImplementation;
    address private lptImplementation;
    uint128 private feeEnabled;
    uint128 private royaltyRate;

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
        address _royaltyEngine
    ) {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeEnabled = _feeRate;
        emit FeeRateChanged(uint128(0), feeEnabled);

        royaltyRate = _royaltyRate;
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
    }

    function feeRecipient() external view returns (address _feeRecipient) {
        _feeRecipient = owner;
    }

    /// @dev The function to create ERC721-ERC20 pair and the nonfungible lp Token contract
    /// @param _token0  The first input token address
    /// @param _token1  The second input token address
    /// @return lpToken The address of lpToken
    /// @return pair    The address of Midas pair
    function createERC721Pair(address _token0, address _token1)
        external
        override
        noDelegateCall
        returns (address lpToken, address pair)
    {
        require(_token0 != _token1 && _token1 != address(0));
        require(IERC721(_token0).supportsInterface(bytes4(0x80ac58cd)));
        require(getPairERC721[_token0][_token1] == address(0));

        lpToken = ImmutableClone.cloneDeterministic(
            lptImplementation,
            "",
            keccak256(abi.encode(_token0, _token1, address(this)))
        );

        pair = ImmutableClone.cloneDeterministic(
            pairImplementation,
            abi.encodePacked(_token0, _token1, lpToken, feeEnabled),
            keccak256(abi.encode(_token0, _token1, lpToken, feeEnabled))
        );

        IMidasPair721(pair).initialize();


        _setRoyaltyInfo(_token0, pair);
        LPToken(lpToken).initialize(pair, _token0, _token1, "MidasLPTOken", "MLPT");

        getPairERC721[_token0][_token1] = pair;
        getLPTokenERC721[_token0][_token1] = lpToken;

        emit PairCreated(_token0, _token1, feeEnabled, pair, lpToken);
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function _setRoyaltyInfo(address _nftAddress, address _pair)
        internal
    {
        (
            address payable[] memory _recipients,
            uint256[] memory _shares
        ) = royaltyEngine.getRoyaltyView(_nftAddress, 1, 1e18);

        if (_shares.length != 0) {
            uint256 _shareSum;
            for (uint256 i; i < _shares.length; ) {
                _shareSum += _shares[i];
                unchecked {
                    ++i;
                }
            }
            for (uint256 i; i < _shares.length; ) {
                _shares[i] = (_shares[i] * 1e18) / _shareSum - 1;
                unchecked {
                    ++i;
                }
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

    function setNewRoyaltyRate(uint128 _newRate) external {
        require(msg.sender == owner);
        royaltyRate = _newRate;
    }

    function setRoyaltyInfo(address _nftAddress, address _pair) external {
        _setRoyaltyInfo(_nftAddress, _pair);
    }
    
    function setPairImplementation(address _newPairImplementation) external {
        require(msg.sender == owner && pairImplementation != _newPairImplementation);
        address _oldPairImplementation = pairImplementation;
        pairImplementation = _newPairImplementation;
        emit PairImplementationSet(
            _oldPairImplementation,
            _newPairImplementation
        );
    }

    function setLptImplementation(address _newLptImplementation) external {
        require(msg.sender == owner && lptImplementation != _newLptImplementation);
        address _oldLptImplementation = lptImplementation;
        lptImplementation = _newLptImplementation;
        emit LptImplementationSet(
            _oldLptImplementation, 
            _newLptImplementation
        );
    }
}