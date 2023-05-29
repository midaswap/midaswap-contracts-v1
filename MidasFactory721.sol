// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {LPToken} from "./LPToken.sol";
import {NoDelegateCall} from "./NoDelegateCall.sol";

import {IMidasPair721} from "./interfaces/IMidasPair721.sol";
import {IMidasFactory721} from "./interfaces/IMidasFactory721.sol";
import {IMidasFlashLoanCallback} from "./interfaces/IMidasFlashLoanCallback.sol";
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
    /// @param _tokenX  The first input token address
    /// @param _tokenY  The second input token address
    /// @return lpToken The address of lpToken
    /// @return pair    The address of Midas pair
    function createERC721Pair(address _tokenX, address _tokenY)
        external
        override
        noDelegateCall
        returns (address lpToken, address pair)
    {
        require(_tokenX != _tokenY && _tokenY != address(0));
        require(IERC721(_tokenX).supportsInterface(bytes4(0x80ac58cd)));
        require(getPairERC721[_tokenX][_tokenY] == address(0));

        lpToken = ImmutableClone.cloneDeterministic(
            lptImplementation,
            "",
            keccak256(abi.encode(_tokenX, _tokenY, address(this)))
        );

        pair = ImmutableClone.cloneDeterministic(
            pairImplementation,
            abi.encodePacked(_tokenX, _tokenY, lpToken, feeEnabled),
            keccak256(abi.encode(_tokenX, _tokenY, lpToken, feeEnabled))
        );

        IMidasPair721(pair).initialize();

        
        LPToken(lpToken).initialize(
            pair,
            _tokenX,
            _tokenY,
            "MidasLPToken",
            "MLPT"
        );

        getPairERC721[_tokenX][_tokenY] = pair;
        getLPTokenERC721[_tokenX][_tokenY] = lpToken;

        _setRoyaltyInfo(_tokenX, _tokenY);

        emit PairCreated(_tokenX, _tokenY, feeEnabled, pair, lpToken);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function _setRoyaltyInfo(address _tokenX, address _tokenY) internal {
        (
            address payable[] memory _recipients,
            uint256[] memory _shares
        ) = royaltyEngine.getRoyaltyView(_tokenX, 1, 1e18);

        address _pair = getPairERC721[_tokenX][_tokenY];

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

    function setNewRoyaltyRate(uint128 _newRate) external override {
        require(msg.sender == owner);
        royaltyRate = _newRate;
    }

    function setRoyaltyInfo(address _tokenX, address _tokenY)
        external
        override
    {
        _setRoyaltyInfo(_tokenX, _tokenY);
    }

    function setPairImplementation(address _newPairImplementation)
        external
        override
    {
        require(
            msg.sender == owner && pairImplementation != _newPairImplementation
        );
        address _oldPairImplementation = pairImplementation;
        pairImplementation = _newPairImplementation;
        emit PairImplementationSet(
            _oldPairImplementation,
            _newPairImplementation
        );
    }

    function setLptImplementation(address _newLptImplementation)
        external
        override
    {
        require(
            msg.sender == owner && lptImplementation != _newLptImplementation
        );
        address _oldLptImplementation = lptImplementation;
        lptImplementation = _newLptImplementation;
        emit LptImplementationSet(_oldLptImplementation, _newLptImplementation);
    }

    function setRoyaltyEngine(address _newRoyaltyEngine) external override {
        require(msg.sender == owner);
        royaltyEngine = IRoyaltyEngineV1(_newRoyaltyEngine);
    }

    function flashLoan(
        address _tokenX,
        address _tokenY,
        IMidasFlashLoanCallback receiver,
        uint256[] calldata _tokenIds,
        bytes calldata data
    ) external {
        require(msg.sender == owner);
        IMidasPair721(getPairERC721[_tokenX][_tokenY]).flashLoan(
            receiver,
            _tokenIds,
            data
        );
    }
}
