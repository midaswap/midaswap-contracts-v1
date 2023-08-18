// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Midas Router Interfaces
/// @author midaswap
/// @notice Providing the interfaces for trading and managing liquidity position

interface IMidasRouter {
    function addLiquidityERC721(
        address _tokenX,
        address _tokenY,
        uint24[] calldata _ids,
        uint256[] calldata _tokenIds,
        uint256 _deadline
    ) external returns (uint256 idAmount, uint128 lpTokenId);

    function addLiquidityERC20(
        address _tokenX,
        address _tokenY,
        uint24[] calldata _ids,
        uint256 _deadline
    ) external returns (uint256 idAmount, uint128 lpTokenId);

    function addLiquidityETH(
        address _tokenX,
        address _tokenY,
        uint24[] calldata _ids,
        uint256 _deadline
    ) external payable returns (uint256 idAmount, uint128 lpTokenId);

    function removeLiquidity(
        address _tokenX,
        address _tokenY,
        uint128 _lpTokenId,
        uint256 _deadline
    ) external returns (uint128 ftAmount);

    function removeLiquidityETH(
        address _tokenX,
        address _tokenY,
        uint128 _lpTokenId,
        uint256 _deadline
    ) external returns (uint128 ftAmount);

    function sellItems(
        address _tokenX,
        address _tokenY,
        uint256[] calldata _tokenIds,
        uint128 _minOutput,
        uint256 _deadline
    ) external returns (uint128 _ftAmount);

    function sellItemsToETH(
        address _tokenX,
        address _tokenY,
        uint256[] calldata _tokenIds,
        uint128 _minOutput,
        uint256 _deadline
    ) external payable returns (uint128 _ftAmount);

    function buyItems(
        address _tokenX,
        address _tokenY,
        uint256[] calldata _tokenIds,
        uint128 _maxInput,
        uint256 _deadline
    ) external returns (uint128 _ftAmount);

    function buyItemsWithETH(
        address _tokenX,
        address _tokenY,
        uint256[] calldata _tokenIds,
        uint128 _maxInput,
        uint256 _deadline
    ) external payable returns (uint128 _ftAmount);

    function openLimitSellOrder(
        address _tokenX,
        address _tokenY,
        uint24[] calldata _ids,
        uint256[] calldata _tokenIds,
        uint256 _deadline
    ) external returns (uint256 idAmount, uint128 lpTokenId);

    function openLimitBuyOrder(
        address _tokenX,
        address _tokenY,
        uint24[] calldata _ids,
        uint256 _deadline
    ) external returns (uint256 idAmount, uint128 lpTokenId);

    function openMultiLimitSellOrders(
        address _tokenX,
        address _tokenY,
        uint24[] calldata _ids,
        uint256[] calldata _tokenIds,
        uint256 _deadline
    ) external returns (uint128[] memory lpTokenIds);

    function openMultiLimitBuyOrder(
        address _tokenX,
        address _tokenY,
        uint24[] calldata _ids,
        uint256 _deadline
    ) external returns (uint128[] memory lpTokenIds);

    function openMultiLimitBuyOrderETH(
        address _tokenX,
        address _tokenY,
        uint24[] calldata _ids,
        uint256 _deadline
    ) external payable returns (uint128[] memory lpTokenIds);

    function claimFee(
        address _tokenX,
        address _tokenY,
        uint128 _lpTokenId
    ) external returns (uint128 _feeClaimed);

    function claimAll(
        address _tokenX,
        address _tokenY,
        uint128[] calldata _lpTokenIds
    ) external returns (uint128 _feeClaimed);

    function getAmountsToAdd(
        address _pair,
        uint24[] calldata _ids
    ) external pure returns (uint128 ftAmount);

    function getMinAmountIn(
        address _pair,
        uint256[] calldata _tokenIds
    ) external view returns (uint128 totalAmount);
}
