// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Midas
/// @author midaswap
/// @notice Helper contract used for fees calculation
library FeeHelper {
    // function getFeeAmountFrom(uint128 _fee, uint128 _amountWithFees) internal pure returns (uint128) {
    //     unchecked{
    //         //in case overflow in uint128 * uint128
    //         return uint128((uint256(_amountWithFees) * _fee + 1e18 - 1) / 1e18);
    //     }
    // }

    function getFeeBaseAndDistribution(
        uint128 _amount,
        uint128 _rateFee,
        uint128 _rateRoyalty
    ) internal pure returns (uint128, uint128, uint128) {
        uint256 _fee;
        uint256 _denominator;
        uint128 _feeBase;
        unchecked {
            _fee = _rateFee + _rateRoyalty;
            _denominator = 1e18 + _fee;
            //in case overflow in uint128 * uint128
            _feeBase =
                _amount -
                uint128(
                    (uint256(_amount) * _fee + _denominator - 1) / _denominator
                );
            return
                getFeeAmountDistributionWithRoyalty(
                    _feeBase,
                    _rateFee,
                    _rateRoyalty
                );
        }
    }

    // Assuming protocol share  = 10%
    function getFeeAmountDistributionWithRoyalty(
        uint128 _feeBase,
        uint128 _rateFee,
        uint128 _rateRoyalty
    )
        internal
        pure
        returns (
            uint128 _feesTotal,
            uint128 _feesProtocol,
            uint128 _feesRoyalty
        )
    {
        unchecked {
            //in case overflow in uint128 * uint128
            _feesTotal = uint128((uint256(_feeBase) * _rateFee) / 1e18);
            _feesProtocol = _feesTotal / 10;
            _feesRoyalty = uint128((uint256(_feeBase) * _rateRoyalty) / 1e18);
        }
    }
}
