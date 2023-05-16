// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockERC721A} from "../assets/MockERC721A.sol";

contract MockAirdrop {

    address public rewardFT;
    address public rewardNFT;
    address public certificateToken;

    constructor(address _ft, address _nft, address _certificate) {
        rewardFT = _ft;
        rewardNFT = _nft;
        certificateToken = _certificate;
    }

    function claimFT() external returns (uint256 claimedAmount) {
        uint256 amount = IERC721(certificateToken).balanceOf(msg.sender);
        require(amount > 0, "AIRDROPER: NOT ELIGIBLE!");
        claimedAmount = amount * 1e19;
        IERC20(rewardFT).safeTransferFrom(address(this), msg.sender, claimedAmount);
    }

    function claimNFT() external returns (uint256 claimedAmount) {
        uint256 amount = IERC721(certificateToken).balanceOf(msg.sender);
        require(amount > 0, "AIRDROPER: NOT ELIGIBLE!");
        claimedAmount = amount;
        MockERC721A(rewardNFT).mint(msg.sender, claimedAmount);
    }

}