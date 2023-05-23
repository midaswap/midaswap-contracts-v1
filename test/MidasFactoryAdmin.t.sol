// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMidasFactory721} from "../interfaces/IMidasFactory721.sol";

contract MidasFactoryAdminTest is Ownable {

    IMidasFactory721 public factory;

    constructor (address _factory) {
        factory = IMidasFactory721(_factory);
    }

    function setOwner(address _owner) external onlyOwner {
        factory.setOwner(_owner);
    }

    function setRoyaltyEngine(address _newRoyaltyEngine) external onlyOwner {
        factory.setRoyaltyEngine(_newRoyaltyEngine);
    }


    function setNewRoyaltyRate(uint128 _newRate) external onlyOwner {
        factory.setNewRoyaltyRate(_newRate);
    }

    function setRoyaltyInfo(address _token0, address _token1) external onlyOwner {
        factory.setRoyaltyInfo(_token0, _token1);
    }

    function setPairImplementation(address _newPairImplementation) external onlyOwner {
        factory.setPairImplementation(_newPairImplementation);
    }

    function setLptImplementation(address _newLptImplementation) external onlyOwner {
        factory.setLptImplementation(_newLptImplementation);
    }

}