// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {LPToken} from "./LPToken.sol";

import {Clone} from "./libraries/Clone.sol";
import {FeeHelper} from "./libraries/FeeHelper.sol";
import {Uint128x128Math} from "./libraries/Math128x128.sol";
import {Math512Bits} from "./libraries/Math512Bits.sol";
import {PackedUint128Math} from "./libraries/PackedUint128Math.sol";
import {PackedUint24Math} from "./libraries/PackedUint24Math.sol";
import {PositionHelper} from "./libraries/PositionHelper.sol";
import {TokenHelper} from "./libraries/TokenHelper.sol";
import {TreeMath} from "./libraries/TreeMath.sol";
import {IMidasPair721} from "./interfaces/IMidasPair721.sol";
import {IMidasFactory721} from "./interfaces/IMidasFactory721.sol";
import {IMidasFlashLoanCallback} from "./interfaces/IMidasFlashLoanCallback.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/// @title Midas Pair
/// @author midaswap
/// @notice This contract is the implementation of Liquidity Book Pair that also acts as the receipt token for liquidity positions

contract MidasPair721 is ERC721Holder, IMidasPair721, Clone {
    error MidasPair__AddressWrong();
    error MidasPair__AmountInWrong();
    error MidasPair__BinSequenceWrong();
    error MidasPair__LengthOrRangeWrong();
    error MidasPair__NFTOwnershipWrong();
    error MidasPair__PriceOverflow();
    error MidasPair__FlashLoanCallbackFailed();
    error MidasPair__SafetyLockWrong();

    using Math512Bits for uint256;
    using TreeMath for TreeMath.TreeUint24;
    using TokenHelper for IERC20;
    using PackedUint128Math for bytes32;
    using PackedUint24Math for bytes32;
    using PackedUint24Math for uint24;
    using FeeHelper for uint128;
    using PositionHelper for uint128[];
    using PositionHelper for uint24[];
    using Uint128x128Math for uint256;

    /// @notice The factory contract that created this pair
    IMidasFactory721 public immutable override factory;

    uint256 private constant MAX = type(uint256).max;

    bytes32 private _Reserves;
    bytes32 private _Fees;
    bytes32 private _RoyaltyInfo;
    bytes32 private _IDs;
    bool private safetyLock;

    address payable[] private creators;
    uint256[] private creatorShares;

    TreeMath.TreeUint24 private _tree;
    TreeMath.TreeUint24 private _tree2;

    /// @dev binIds -> binReserves (reservesX , reservesY)
    mapping(uint24 => bytes32) private _bins;
    /// @dev lpTokenId -> BinParams (originID , binStep , unclaimedFee)
    mapping(uint128 => bytes32) private lpInfos;
    /// @dev lpTokenId -> NFT tokenIds
    mapping(uint128 => uint256[]) private lpTokenAssetsMap;
    /// @dev NFT tokenIds -> lpTokenId
    mapping(uint256 => uint128) private assetLPMap;
    /// @dev binIds -> lpTokenIds
    mapping(uint24 => uint128[]) private binLPMap;

    /** Constructor **/

    constructor(address _factory) {
        factory = IMidasFactory721(_factory);
    }

    function initialize() external override {
        _checkSenderAddress(address(factory));
        _IDs = 0x0000000000000000000000000000000000000000000000000000ffffff000000;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Returns the token X of the Pair
     * @return tokenX The address of the token X
     */
    function getTokenX() external pure override returns (IERC721) {
        return tokenX();
    }

    /**
     * @notice Returns the token Y of the Pair
     * @return tokenY The address of the token Y
     */
    function getTokenY() external pure override returns (IERC20) {
        return tokenY();
    }

    /**
     * @notice Returns the LP Token of the Pair
     * @return lpToken The address of the LPToken
     */
    function getLPToken() external pure override returns (LPToken) {
        return lpToken();
    }

    /**
     * @notice Returns the reserves of the Pair
     * This is the sum of the reserves of all bins.
     * @return reserveX The reserve of token X
     * @return reserveY The reserve of token Y
     */
    function getReserves() external view override returns (uint128, uint128) {
        return _Reserves.decode();
    }

    /**
     * @notice Returns the IDs of the Pair
     * @return bestOfferID The best offer bin of the Pair
     * @return floorPriceID The floor price bin of the Pair
     * @return currentPositionID The current LP Token ID of the Pair
     */
    function getIDs()
        external
        view
        override
        returns (
            uint24 bestOfferID,
            uint24 floorPriceID,
            uint128 currentPositionID
        )
    {
        return _IDs.getAll();
    }

    /**
     * @notice Returns the Fees of the Pair
     * @return totalFees The Total Fees reserve of the Pair, including Protocol Fees
     * @return protocolFees The Protocol Fees reserve of the Pair
     */
    function getGlobalFees() external view override returns (uint128, uint128) {
        return _Fees.decode();
    }

    /**
     * @notice Returns the Fees of the Pair
     * @return rate The Fee rate of the Pair, including Protocol Fee
     * @return protocolRate The Protocol rate of the Pair, persentage of the Fee
     * @return royaltyRate The Royalty rate of the Pair
     */
    function feeParameters()
        external
        view
        override
        returns (uint128 rate, uint128 protocolRate, uint128 royaltyRate)
    {
        rate = 5e15;
        protocolRate = 1e17;
        royaltyRate = _RoyaltyInfo.decodeX();
    }

    /**
     * @notice Return the reserves of the bin at `id`
     * @param _id The bin id
     * @return reserveX The reserve of tokenX of the bin
     * @return reserveY The reserve of tokenY of the bin
     */
    function getBin(
        uint24 _id
    ) external view override returns (uint128, uint128) {
        return _bins[_id].decode();
    }

    /**
     * @notice Returns data of the LP `_LPtokenID`
     * @param _LPtokenID The LP Token id
     * @return originBin The first bin of the LP liquidity
     * @return binStep The binStep of the LP liquidity
     * @return lpFee The Fee reserve under this LP
     */
    function getLpInfos(
        uint128 _LPtokenID
    ) external view override returns (uint24, uint24, uint128) {
        return lpInfos[_LPtokenID].getAll();
    }

    /**
     * @notice Returns the price corresponding to the given id
     * @param _id The id of the bin
     * @return price The price corresponding to this id
     */
    function getPriceFromBin(
        uint24 _id
    ) external pure override returns (uint128) {
        return _getPriceFromBin(_id);
    }

    /**
     * @notice Returns the LPToken ID that owns the given NFT in the Pair
     * @param _NFTID The id of the NFT
     * @return LPtokenID The LPToken ID corresponding to this NFT
     */
    function getLPFromNFT(
        uint256 _NFTID
    ) external view override returns (uint128) {
        return assetLPMap[_NFTID];
    }

    /**
     * @notice Returns the Total Price of `_amount` NFTs from `_lpTokenID`, not including fee.
     * @param _lpTokenID The id of the LP Token
     * @param _amount The amount of NFTs
     * @return _totalPrice The Total Price of these NFTs
     */
    function getBinParamFromLP(
        uint128 _lpTokenID,
        uint256 _amount
    ) external view override returns (uint128 _totalPrice) {
        uint256[] memory _map;
        uint24 i;
        uint24 _start;
        uint24 _binStep;
        bytes32 _lpInfo;
        _map = lpTokenAssetsMap[_lpTokenID];
        _lpInfo = lpInfos[_lpTokenID];
        (_start, _binStep) = _lpInfo.getBothUint24();
        for (uint256 j; j < _amount; ) {
            if (_map[i] != MAX) {
                _totalPrice += _getPriceFromBin(_start + _binStep * i);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns the Liquidity Reserves of give LP Token, including LP Fees.
     * @param _lpTokenID The id of the LP Token
     * @return reserveX The reserve of tokenX of the LP Token
     * @return reserveY The reserve of tokenY of the LP Token, including LP Fees.
     */
    function getLpReserve(
        uint128 _lpTokenID
    ) external view override returns (uint128, uint128) {
        uint256 _length;
        uint128 amountX;
        uint128 amountY;
        uint128 fee;
        uint128 _price;
        uint24 originBin;
        uint24 binStep;
        uint24 _id;
        uint256[] memory lpAsset;
        lpAsset = lpTokenAssetsMap[_lpTokenID];
        _length = lpAsset.length;
        (originBin, binStep, fee) = lpInfos[_lpTokenID].getAll();
        if (_lpTokenID & 0x1 != 0) return (0, 0);
        for (uint24 i; i < _length; ) {
            if (lpAsset[i] != MAX) {
                unchecked {
                    amountX += 1e18;
                }
            } else {
                unchecked {
                    _id = originBin + i * binStep;
                }
                _price = _getPriceFromBin(_id);
                unchecked {
                    amountY += _price;
                }
            }
            unchecked {
                ++i;
            }
        }
        unchecked {
            amountY += fee;
        }
        return (amountX, amountY);
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice Sell tokenX at best offer price.
     * Token X will be swapped for token Y.
     * This function will not transfer the tokenX from the caller, it is expected that the tokenX have already been
     * transferred to this contract through another contract, most likely the router.
     * That is why this function shouldn't be called directly, but only through one of the swap functions of a router
     * @param NFTID The ID of NFT that user wants to sell
     * @param _to The address to send the tokenY to
     * @return _amountOut The amounts of token Y sent to `to`
     */
    function sellNFT(
        uint256 NFTID,
        address _to
    ) external override returns (uint128 _amountOut) {
        _checkSafetyLock();
        uint24 _tradeID;
        bytes32 _royaltyInfo;
        uint128 _amountOutOfBin;
        uint128 _feesTotal;
        uint128 _feesProtocol;
        uint128 _feesRoyalty;

        _tradeID = _IDs.getFirstUint24();
        _royaltyInfo = _RoyaltyInfo;
        _amountOutOfBin = _getPriceFromBin(_tradeID);
        (_feesTotal, _feesProtocol, _feesRoyalty) = _amountOutOfBin
            .getFeeBaseAndDistribution(_royaltyInfo.decodeX());

        unchecked {
            _amountOut = _amountOutOfBin - _feesTotal - _feesRoyalty;
        }

        uint128 _LPtokenID;
        _LPtokenID = binLPMap[_tradeID][binLPMap[_tradeID].length - 1];
        binLPMap[_tradeID].pop();
        _checkNFTOwner(NFTID);
        //
        assetLPMap[NFTID] = _LPtokenID;

        // update _RoyaltyInfo
        _royaltyInfo = _royaltyInfo.addSecond(_feesRoyalty);
        _RoyaltyInfo = _royaltyInfo;

        _updateAssetMapSell(_LPtokenID, _tradeID, NFTID);

        _updateLpInfo(_LPtokenID, _feesTotal - _feesProtocol);

        // update _Fees
        bytes32 _fees;
        _fees = _Fees;
        _fees = _fees.add(_feesTotal, _feesProtocol);
        _Fees = _fees;

        // update _Reserves
        bytes32 _reserves;
        _reserves = _Reserves;
        _reserves = _reserves.addFirst(1e18).subSecond(_amountOutOfBin);
        _Reserves = _reserves;

        // update _bins
        bytes32 _bin;
        _bin = _bins[_tradeID];
        _bin = _bin.addFirst(1).subSecond(1);
        _bins[_tradeID] = _bin;
        // update trees
        if (_bin.decodeX() == 1) _tree2.add(_tradeID);
        if (_bin.decodeY() == 0) _tree.remove(_tradeID);
        // update _IDs
        _updateIDs(0);

        tokenY().safeTransfer(_to, _amountOut);
        //
        emit SellNFT(NFTID, _to, _tradeID, _LPtokenID);
    }

    /**
     * @notice Buy tokenX at corresponding price.
     * Token Y will be swapped for token X.
     * This function will not transfer the tokenY from the caller, it is expected that the tokenY have already been
     * transferred to this contract through another contract, most likely the router.
     * That is why this function shouldn't be called directly, but only through one of the swap functions of a router
     * @param NFTID The ID of NFT that user wants to buy
     * @param _to The address to send the tokenY to
     */
    function buyNFT(uint256 NFTID, address _to) external override {
        _checkSafetyLock();
        uint128 _LPtokenID;
        uint24 _tradeId;
        bytes32 _bin;
        bytes32 _royaltyInfo;
        bytes32 _reserves;
        bytes32 _fees;
        uint128 _amountInToBin;
        uint128 _feesTotal;
        uint128 _feesProtocol;
        uint128 _feesRoyalty;

        _LPtokenID = assetLPMap[NFTID];
        _tradeId = _updateAssetMapBuy(_LPtokenID, NFTID);
        _bin = _bins[_tradeId];
        _royaltyInfo = _RoyaltyInfo;
        _reserves = _Reserves;
        _fees = _Fees;
        _amountInToBin = _getPriceFromBin(_tradeId);
        (_feesTotal, _feesProtocol, _feesRoyalty) = _amountInToBin
            .getFeeAmountDistributionWithRoyalty(_royaltyInfo.decodeX());

        delete assetLPMap[NFTID];

        if (
            _amountInToBin + _feesTotal + _feesRoyalty >
            tokenY().received(
                _reserves.decodeY(),
                _fees.decodeX(),
                _royaltyInfo.decodeY()
            )
        ) revert MidasPair__AmountInWrong();

        _royaltyInfo = _royaltyInfo.addSecond(_feesRoyalty);

        if (_LPtokenID & 0x1 == 0) {
            // NFT from NFT LPs
            if (_bin.decodeY() == 0) _tree.add(_tradeId);
            binLPMap[_tradeId].push(_LPtokenID);

            _updateLpInfo(_LPtokenID, _feesTotal - _feesProtocol);
            _fees = _fees.add(_feesTotal, _feesProtocol);
            _reserves = _reserves.subFirst(1e18).addSecond(_amountInToBin);
            _bin = _bin.subFirst(1).addSecond(1);
        } else {
            // NFT from Limited Orders
            _updateLpInfo(_LPtokenID, _amountInToBin);
            _fees = _fees.add(_amountInToBin + _feesTotal, _feesTotal);
            _reserves = _reserves.subFirst(1e18);
            _bin = _bin.subFirst(1);
        }

        //update trees
        if (_bin.decodeX() == 0) _tree2.remove(_tradeId);

        _updateIDs(0);
        _bins[_tradeId] = _bin;
        _RoyaltyInfo = _royaltyInfo;
        _Reserves = _reserves;
        _Fees = _fees;

        tokenX().safeTransferFrom(address(this), _to, NFTID);
        emit BuyNFT(NFTID, _to, _tradeId, _LPtokenID);
    }

    /**
     * @notice Mint liquidity token by depositing tokenXs into the pool.
     * It will mint one LP tokens for all bins where the user adds liquidity.
     * This function will not transfer the tokenX from the caller, it is expected that the tokenX have already been
     * transferred to this contract through another contract, most likely the router.
     * That is why this function shouldn't be called directly, but through one of the add liquidity functions of a
     * router that will also perform safety checks.
     * @param _ids The BinID List that user want to add liquidity to
     * @param _NFTIDs The NFTID list that the user want to add to the given bins
     * @param _to The address that will receive the LP Token
     * @param isLimited Whether user is makeing limited order (true) or provide liquidity as LP (false)
     * @return _amount The amounts of token X received by the pool
     * @return _lpTokenID The ID of the LPToken the user will receive
     */
    function mintNFT(
        uint24[] calldata _ids,
        uint256[] calldata _NFTIDs,
        address _to,
        bool isLimited
    ) external override returns (uint256, uint128) {
        _checkSafetyLock();
        uint256 _length;
        uint128 currentPositionID;
        _length = _ids.length;
        currentPositionID = _IDs.getUint128();
        unchecked {
            (currentPositionID & 0x1 == 0) == (isLimited)
                ? currentPositionID += 1
                : currentPositionID += 2;
        }
        uint24 originBin;
        uint24 binStep;
        (originBin, binStep) = _ids._checkBinSequence();
        if (
            originBin < _IDs.getFirstUint24() ||
            originBin < 7974122 ||
            _length != _NFTIDs.length ||
            _length > 100
        ) revert MidasPair__LengthOrRangeWrong();
        lpInfos[currentPositionID] = originBin.setAll(binStep, 0);
        lpTokenAssetsMap[currentPositionID] = _NFTIDs;

        uint24 _id;
        bytes32 _bin;
        for (uint256 i; i < _length; ) {
            _id = _ids[i];
            _bin = _bins[_id];
            if (_bin.decodeX() == 0) _tree2.add(_id);
            _checkNFTOwner(_NFTIDs[i]);
            //
            assetLPMap[_NFTIDs[i]] = currentPositionID;
            _bin = _bin.addFirst(1);
            if (_bin.sum() > 100) revert MidasPair__LengthOrRangeWrong();
            _bins[_id] = _bin;
            unchecked {
                ++i;
            }
        }

        emit ERC721PositionMinted(
            currentPositionID,
            originBin,
            binStep,
            _NFTIDs
        );

        bytes32 _reserves;
        _reserves = _Reserves;
        unchecked {
            _reserves = _reserves.addFirst(uint128(_length) * 1e18);
        }
        _Reserves = _reserves;

        _updateIDs(currentPositionID);

        lpToken().mint(_to, currentPositionID);
        //

        return (_length, currentPositionID);
    }

    /**
     * @notice Mint LP token by depositing tokenYs into the pool.
     * It will mint one LP tokens for all bins where the user adds liquidity.
     * This function will not transfer the tokenY from the caller, it is expected that the tokenY have already been
     * transferred to this contract through another contract, most likely the router.
     * That is why this function shouldn't be called directly, but through one of the add liquidity functions of a
     * router that will also perform safety checks.
     * @param _ids The BinID List that user want to add liquidity to
     * @param _to The address that will receive the LP Token
     * @return _amount The amounts of token Y received by the pool
     * @return _lpTokenID The ID of the LPToken the user will receive
     */
    function mintFT(
        uint24[] calldata _ids,
        address _to
    ) external override returns (uint128, uint128) {
        _checkSafetyLock();
        bytes32 _tempIDs;
        uint128 currentPositionID;
        uint128 _amountYAddedToPair;
        uint256 _length;

        _tempIDs = _IDs;
        currentPositionID = _tempIDs.getUint128();
        _length = _ids.length;

        unchecked {
            currentPositionID & 0x1 == 0
                ? currentPositionID += 2
                : currentPositionID += 1;
        }
        uint24 originBin;
        uint24 binStep;
        (originBin, binStep) = _ids._checkBinSequence();
        lpInfos[currentPositionID] = originBin.setAll(binStep, 0);

        if (
            _ids[_length - 1] > _tempIDs.getSecondUint24() ||
            originBin < 7974122 ||
            _length > 100
        ) revert MidasPair__LengthOrRangeWrong();

        bytes32 _bin;
        uint24 _mintId;
        uint128 _price;
        uint256[] memory newMap;
        newMap = new uint256[](_length);

        for (uint256 i; i < _length; ) {
            _mintId = _ids[i];
            _bin = _bins[_mintId];
            if (_bin.decodeY() == 0) _tree.add(_mintId);
            _price = _getPriceFromBin(_mintId);
            _bin = _bin.addSecond(1);
            _amountYAddedToPair += _price;
            if (_bin.sum() > 100) revert MidasPair__LengthOrRangeWrong();
            _bins[_mintId] = _bin;
            binLPMap[_mintId].push(currentPositionID);
            newMap[i] = MAX;

            unchecked {
                ++i;
            }
        }

        bytes32 _reserves;
        _reserves = _Reserves;
        if (
            _amountYAddedToPair >
            tokenY().received(
                _reserves.decodeY(),
                _Fees.decodeX(),
                _RoyaltyInfo.decodeY()
            )
        ) revert MidasPair__AmountInWrong();
        //

        _reserves = _reserves.addSecond(_amountYAddedToPair);
        _Reserves = _reserves;

        lpTokenAssetsMap[currentPositionID] = newMap;

        _updateIDs(currentPositionID);

        lpToken().mint(_to, currentPositionID);
        //
        emit ERC20PositionMinted(
            currentPositionID,
            originBin,
            binStep,
            _length
        );
        return (_amountYAddedToPair, currentPositionID);
    }

    /**
     * @notice Burn LP tokens and withdraw tokens from the pool.
     * This function will burn the tokens directly from the caller
     * @param _LPtokenID The LP Token that will be burned
     * @param _nftReceiver The address that will receive tokenXs from the pool
     * @param _to The address that will receive tokenYs from the pool
     * @return amountX The amounts of token X received by the user
     * @return amountY The amounts of token Y received by the user
     */
    function burn(
        uint128 _LPtokenID,
        address _nftReceiver,
        address _to
    ) external override returns (uint128 amountX, uint128 amountY) {
        uint256[] memory _tokenIds;
        uint256 _binIdLength;
        uint24 originBin;
        uint24 binStep;
        uint128 amountFee;

        _tokenIds = lpTokenAssetsMap[_LPtokenID];
        _binIdLength = _tokenIds.length;
        if (_binIdLength == 0) revert MidasPair__LengthOrRangeWrong();
        (originBin, binStep, amountFee) = lpInfos[_LPtokenID].getAll();
        _checkLPTOwner(_LPtokenID, address(this));
        delete lpTokenAssetsMap[_LPtokenID];
        delete lpInfos[_LPtokenID];

        uint128 _price;
        uint24 _id;
        bytes32 _bin;
        for (uint24 i; i < _binIdLength; ) {
            unchecked {
                _id = originBin + i * binStep;
            }
            _bin = _bins[_id];
            if (_tokenIds[i] != MAX) {
                delete assetLPMap[_tokenIds[i]];

                _bin = _bin.subFirst(1);
                unchecked {
                    amountX += 1e18;
                }

                if (_bin.decodeX() == 0) _tree2.remove(_id);

                tokenX().safeTransferFrom(
                    address(this),
                    _nftReceiver,
                    _tokenIds[i]
                );
            } else if (_LPtokenID & 0x1 == 0) {
                binLPMap[_id] = binLPMap[_id]._findIndexAndRemove(_LPtokenID);

                _price = _getPriceFromBin(_id);
                _bin = _bin.subSecond(1);
                unchecked {
                    amountY += _price;
                }

                if (_bin.decodeY() == 0) _tree.remove(_id);
            }
            _bins[_id] = _bin;

            unchecked {
                ++i;
            }
        }

        bytes32 _reserves;
        _reserves = _Reserves;
        _reserves = _reserves.sub(amountX, amountY);
        _Reserves = _reserves;

        _updateIDs(0);

        _updateFees(amountFee);

        emit PositionBurned(_LPtokenID, _nftReceiver, amountFee);

        amountY += amountFee;
        tokenY().safeTransfer(_to, amountY);
    }

    /**
     * @notice Collect the protocol fees and send them to the fee recipient.
     * @return amountY The amount of token Y collected and sent to the fee recipient
     */
    function collectProtocolFees() external override returns (uint128 amountY) {
        address _feeRecipient;
        bytes32 fees;
        _feeRecipient = factory.feeRecipient();
        _checkSenderAddress(_feeRecipient);
        fees = _Fees;
        amountY = fees.decodeY();
        _Fees = fees.sub(amountY, amountY);
        tokenY().safeTransfer(_feeRecipient, amountY);
    }

    /**
     * @notice Collect the protocol fees and send them to the fee recipient.
     * @param _LPtokenID The LP Token ID that user claims fee from
     * @param _to The address that will receive tokenYs from the pool
     * @return amountFee The amount of token Y collected and sent to the given address
     */
    function collectLPFees(
        uint128 _LPtokenID,
        address _to
    ) external override returns (uint128 amountFee) {
        bytes32 _lpInfo;
        _checkLPTOwner(_LPtokenID, _to);
        _lpInfo = lpInfos[_LPtokenID];
        amountFee = _lpInfo.getUint128();
        lpInfos[_LPtokenID] = _lpInfo.setUint128(0);
        _updateFees(amountFee);

        tokenY().safeTransfer(_to, amountFee);
        emit ClaimFee(_LPtokenID, _to, amountFee);
    }

    /**
     * @notice Collect the royalty fees and send them to the fee recipients.
     * @return _royaltyFees The total amount of token Y collected and sent to the fee recipients
     */
    function collectRoyaltyFees()
        external
        override
        returns (uint128 _royaltyFees)
    {
        bytes32 _royaltyInfo;
        _royaltyInfo = _RoyaltyInfo;
        _royaltyFees = _royaltyInfo.decodeY();
        _RoyaltyInfo = _royaltyInfo.setSecond(0);
        unchecked {
            for (uint256 i; i < creators.length; ++i) {
                tokenY().safeTransfer(
                    creators[i],
                    (creatorShares[i] * _royaltyFees) / 1e18
                );
            }
        }
    }

    /**
     * @notice Reset the royalty information of the pair
     * @dev This function can only be called by factory
     * @param _newRate The new royalty rate
     * @param newrecipients The new royalty recipients
     * @param newshares The new royalty shares that each recipient owns
     */
    function updateRoyalty(
        uint128 _newRate,
        address payable[] calldata newrecipients,
        uint256[] calldata newshares
    ) external override {
        _checkSenderAddress(address(factory));
        creators = newrecipients;
        creatorShares = newshares;
        _RoyaltyInfo = _RoyaltyInfo.setFirst(_newRate);
        emit NewRoyaltyFee(_newRate);
    }

    /**
     * @notice Change the status of the pair lock
     * @dev This function can only be called by factory
     * @param lock The new lock status
     */
    function updateSafetyLock(bool lock) external override {
        _checkSenderAddress(address(factory));
        safetyLock = lock;
    }

    /**
     * @notice Flash loan tokenXs from the pool to a receiver contract and execute a callback function.
     * The receiver contract is expected to return the tokens to this contract.
     * @param receiver The contract that will receive the tokens and execute the callback function
     * @param _tokenIds The IDs of NFTs that will be borrowed
     * @param data Any data that will be passed to the callback function
     */
    function flashLoan(
        IMidasFlashLoanCallback receiver,
        uint256[] calldata _tokenIds,
        bytes calldata data
    ) external override {
        _checkSenderAddress(address(factory));
        uint256 length;
        length = _tokenIds.length;
        for (uint256 i; i < length; ) {
            tokenX().safeTransferFrom(
                address(this),
                address(receiver),
                _tokenIds[i]
            );
            unchecked {
                ++i;
            }
        }

        receiver.MidasFlashLoanCallback(tokenX(), _tokenIds, data);

        for (uint256 i; i < length; ) {
            if (tokenX().ownerOf(_tokenIds[i]) != address(this))
                revert MidasPair__NFTOwnershipWrong();
            unchecked {
                ++i;
            }
        }

        emit FlashLoan(msg.sender, receiver, _tokenIds);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Returns the token X of the Pair
     * @return tokenX The address of the token X
     */
    function tokenX() private pure returns (IERC721) {
        return IERC721(_getArgAddress(0));
    }

    /**
     * @dev Returns the token Y of the Pair
     * @return tokenX The address of the token Y
     */
    function tokenY() private pure returns (IERC20) {
        return IERC20(_getArgAddress(20));
    }

    /**
     * @dev Returns the LP Token of the Pair
     * @return lpToken The address of the LPToken
     */
    function lpToken() private pure returns (LPToken) {
        return LPToken(_getArgAddress(40));
    }

    /**
     * @dev Returns the price corresponding to the given id
     * @param _id The id of the bin
     * @return price The price corresponding to this id
     */
    function _getPriceFromBin(uint24 _id) private pure returns (uint128) {
        int256 _realId;
        uint256 _price;
        // 2^23 = 8388608
        _realId = int256(uint256(_id)) - 8388608;
        // 2^128 * 1.0001 = 340316395157630557309720944892511388277
        _price = uint256(340316395157630557309720944892511388277).pow(_realId);
        _price = _price.mulShiftRoundDownS();
        if (_price > type(uint128).max) revert MidasPair__PriceOverflow();
        return uint128(_price);
    }

    /**
     * @dev Checks whether the pool received the given NFT
     * @param _NFTID The id of the NFT
     */
    function _checkNFTOwner(uint256 _NFTID) internal view {
        if (
            assetLPMap[_NFTID] != 0 || tokenX().ownerOf(_NFTID) != address(this)
        ) revert MidasPair__NFTOwnershipWrong();
    }

    /**
     * @dev Checks whether the given address owns the given LP Token
     * @param _lpTokenID The id of the LP Token
     * @param _to The address to be checked
     */
    function _checkLPTOwner(uint256 _lpTokenID, address _to) internal view {
        if (_to != lpToken().ownerOf(_lpTokenID))
            revert MidasPair__AddressWrong();
    }

    /**
     * @dev Checks whether the given address is the message sender
     * @param _target The address to be compared
     */
    function _checkSenderAddress(address _target) internal view {
        if (_target != msg.sender) revert MidasPair__AddressWrong();
    }

    function _checkSafetyLock() internal view {
        if (safetyLock == true) revert MidasPair__SafetyLockWrong();
    }

    /**
     * @dev Updates the _IDs of the Pair
     * @param currentPositionID The current LP Token ID of the Pair
     */
    function _updateIDs(uint128 currentPositionID) internal {
        uint24 bestOfferID;
        uint24 floorPriceID;
        bytes32 _ids;
        (bestOfferID, floorPriceID) = _tree.updateBins(_tree2);
        _ids = _IDs;
        if (currentPositionID == 0) {
            _ids = _ids.setBothUint24(bestOfferID, floorPriceID);
        } else {
            _ids = bestOfferID.setAll(floorPriceID, currentPositionID);
        }
        _IDs = _ids;
    }

    /**
     * @dev Updates the _Fees of the Pair
     * @param amount The amount of token Y to be subtracted from the totalFees in the Fee parameter
     */
    function _updateFees(uint128 amount) internal {
        bytes32 _fees;
        _fees = _Fees;
        _fees = _fees.subFirst(amount);
        _Fees = _fees;
    }

    /**
     * @dev Updates the LP Fee of the given LP token
     * @param _lpToken The LP token ID that will be updated
     * @param amountY The amount of token Y to be added to the LP Fee
     */
    function _updateLpInfo(uint128 _lpToken, uint128 amountY) internal {
        bytes32 _info;
        _info = lpInfos[_lpToken];
        _info = _info.addUint128(amountY);
        lpInfos[_lpToken] = _info;
    }

    /**
     * @dev Returnss the ID of the bin where trading happens
     * @dev Updates LPs reserve distribution when buying NFT
     * @param _lpTokenID The LP token ID that owns the given tokenX
     * @param _NFTID The ID of given NFT
     * @return _currentID The ID of the bin where the trading should happen
     */
    function _updateAssetMapBuy(
        uint128 _lpTokenID,
        uint256 _NFTID
    ) internal returns (uint24 _currentID) {
        uint256[] memory _map;
        uint24 _start;
        uint24 _binStep;
        uint24 _index;
        uint256 temp;
        uint256 asset;
        _map = lpTokenAssetsMap[_lpTokenID];
        (_start, _binStep) = lpInfos[_lpTokenID].getBothUint24();
        temp = MAX;
        for (uint24 i; i < _map.length; ) {
            asset = _map[i];
            if (asset != MAX) {
                if (temp == MAX) {
                    temp = asset;
                    _index = i;
                    lpTokenAssetsMap[_lpTokenID][i] = MAX;
                    if (temp == _NFTID) break;
                } else if (asset == _NFTID) {
                    lpTokenAssetsMap[_lpTokenID][i] = temp;
                    break;
                }
            }
            unchecked {
                ++i;
            }
        }
        unchecked {
            _currentID = _index * _binStep + _start;
        }
    }

    /**
     * @dev Updates LPs reserve distribution when selling NFT
     * @param _lpTokenID The LP token ID that owns the corresponding tokenY
     * @param _tradeID The ID of the bin where the trading happens
     * @param _NFTID The ID of given NFT
     */
    function _updateAssetMapSell(
        uint128 _lpTokenID,
        uint24 _tradeID,
        uint256 _NFTID
    ) internal {
        uint24 _index;
        uint24 _start;
        uint24 _binStep;
        (_start, _binStep) = lpInfos[_lpTokenID].getBothUint24();
        if (_binStep != 0) {
            unchecked {
                _index = (_tradeID - _start) / _binStep;
            }
        } else {
            uint256[] memory _map;
            _map = lpTokenAssetsMap[_lpTokenID];
            while (_map[_index] != MAX) {
                unchecked {
                    ++_index;
                }
            }
        }
        lpTokenAssetsMap[_lpTokenID][_index] = _NFTID;
    }
}
