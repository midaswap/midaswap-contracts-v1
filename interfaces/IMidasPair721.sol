// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IMidasFactory721} from "./IMidasFactory721.sol";
import {IMidasFlashLoanCallback} from "./IMidasFlashLoanCallback.sol";
import {LPToken} from "../LPToken.sol";

/// @title Midas Pair Interface
/// @author midaswap
/// @notice Required interface of Midas Pair contract

interface IMidasPair721 {
    event SellNFT(
        uint256 indexed nftTokenId,
        address indexed from,
        uint24 tradeBin,
        uint128 indexed lpTokenID
    );

    event BuyNFT(
        uint256 indexed nftTokenId,
        address indexed from,
        uint24 tradeBin,
        uint128 indexed lpTokenID
    );

    event ERC721PositionMinted(
        uint128 indexed lpTokenId,
        uint24 indexed binLower,
        uint24 indexed binStep,
        uint256[] _NFTIDs
    );

    event ERC20PositionMinted(
        uint128 indexed lpTokenId,
        uint24 indexed binLower,
        uint24 indexed binStep,
        uint256 binAmount
    );

    event PositionBurned(
        uint128 indexed lpTokenId,
        address indexed owner,
        uint128 indexed feeCollected
    );

    event ClaimFee(uint128 indexed lpTokenId, address indexed owner, uint256 indexed feeCollected);

    event FlashLoan(
        address indexed caller,
        IMidasFlashLoanCallback receiver,
        uint256[] NFTIDs
    );

    function initialize() external;

    function getTokenX() external view returns (IERC721);

    function getTokenY() external view returns (IERC20);

    function getLPToken() external view returns (LPToken);

    function factory() external view returns (IMidasFactory721);

    function getReserves()
        external
        view
        returns (uint128 reserveX, uint128 reserveY);

    function getIDs()
        external
        view
        returns (
            uint24 bestOfferID,
            uint24 floorPriceID,
            uint128 currentPositionID
        );

    function getGlobalFees()
        external
        view
        returns (uint128 feesYTotal, uint128 feesYProtocol);

    function feeParameters() external view returns (uint128, uint128, uint128);

    function getBin(
        uint24 id
    ) external view returns (uint128 reserveX, uint128 reserveY);

    function getLpInfos(
        uint128 _LPtokenID
    ) external view returns (uint24 originBin, uint24 binStep, uint128 _fee);

    function getPriceFromBin(uint24 _id) external pure returns (uint128 _Price);

    function getLPFromNFT(
        uint256 _NFTID
    ) external view returns (uint128 _LPtoken);

    function getBinParamFromLP(
        uint128 _lpTokenID,
        uint256 _amount
    ) external view returns (uint128 _totalPrice);

    function getLpReserve(
        uint128 _lpTokenID
    ) external view returns (uint128 amountX, uint128 amountY);

    function sellNFT(
        uint256 NFTID,
        address _to
    ) external returns (uint128 _amountOut);

    function buyNFT(uint256 NFTID, address _to) external;

    function mintNFT(
        uint24[] calldata ids,
        uint256[] calldata NFTIDs,
        address to,
        bool isLimited
    ) external returns (uint256 number, uint128 LPtokenID);

    function mintFT(
        uint24[] calldata ids,
        address to
    ) external returns (uint128 amountIn, uint128 LPtokenID);

    function burn(
        uint128 LPtokenID,
        address _nftReceiver,
        address to
    ) external returns (uint128 amountX, uint128 amountY);

    function collectProtocolFees() external returns (uint128 amountY);

    function collectLPFees(
        uint128 LPtokenID,
        address _to
    ) external returns (uint128 amountFee);

    function collectRoyaltyFees() external returns (uint128 amountY);

    function updateRoyalty(
        uint128 _newRate,
        address payable[] calldata newrecipients,
        uint256[] calldata newshares
    ) external;

    function updateSafetyLock(
        bool newLock
    ) external;

    function flashLoan(
        IMidasFlashLoanCallback receiver,
        uint256[] calldata NFTlist,
        bytes calldata data
    ) external;
}
