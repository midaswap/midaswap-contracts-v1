// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Midas
/// @author midaswap
/// @notice Helper contract used for fees calculation
library FeeHelper {
    
    /**
     * @notice Internal function to calculate the fees
     * @param _amount The total amount (fee + fee base)
     * @param _rateFee The rate of trading fee
     * @param _rateRoyalty The rate of royalty fee
     * @return _feesTotal The total trading fee
     * @return _feesProtocol The protocol fee
     * @return _feesRoyalty The royalty fee
     */
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

    /**
     * @notice Internal function to calculate the fees
     * @dev Assuming protocol share  = 10%
     * @param _feeBase The fee base
     * @param _rateFee The rate of trading fee
     * @param _rateRoyalty The rate of royalty fee
     * @return _feesTotal The total trading fee
     * @return _feesProtocol The protocol fee
     * @return _feesRoyalty The royalty fee
     */
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
