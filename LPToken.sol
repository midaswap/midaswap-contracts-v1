// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC721} from "./libraries/ERC721.sol";
import {Strings} from "./libraries/Strings.sol";
import {IMidasPair721} from "./interfaces/IMidasPair721.sol";

/// @title Midas LP Token
/// @author midaswap
/// @notice Non-fungible token which wraps the positions of LPs

contract LPToken is ERC721 {

    using Strings for uint256;
    using Strings for address;

    // Pair address
    address private pair;
    // Factory address
    address private factory;
    // Token X address
    address private tokenX;
    // Token Y address
    address private tokenY;
    // Maintain State of LPT contract
    bool private initialized;

    constructor(address _factory) ERC721("Midas LP Token", "MLPT") {
        factory = _factory;
        initialized = false;
    }

    function initialize(
        address _pair,
        address _tokenX,
        address _tokenY
    ) external virtual {
        require(initialized == false);
        pair = _pair;
        tokenX = _tokenX;
        tokenY = _tokenY;
        initialized = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_ownerOf[tokenId] != address(0));
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenX.toHexString(),
                        "/",
                        tokenY.toHexString(),
                        "/",
                        tokenId.toString()
                    )
                )
                : "";
    }

    function mint(address to, uint256 tokenId) external virtual {
        require(msg.sender == pair);
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external virtual {
        require(msg.sender == pair);
        _burn(tokenId);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "www.midaswap.org/";
    }

    function getReserves(uint128 tokenId) external view virtual returns (uint256 xReserves, uint256 yReserves) {
        (xReserves, yReserves) = IMidasPair721(pair).getLpReserve(tokenId);
    }
}
