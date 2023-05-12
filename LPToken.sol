// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC721} from "./libraries/ERC721.sol";
import {Strings} from "./libraries/Strings.sol";
import {IMidasPair721} from "./interfaces/IMidasPair721.sol";

/// @title Midas LP Token
/// @author midaswap
/// @notice Non-fungible token which wraps the positions of LPs

contract LPToken is ERC721 {

    string public name;
    string public symbol;

    using Strings for uint256;
    using Strings for address;

    // Factory address
    address public immutable factory;
    // Pair address
    address public pair;
    // Token X address
    address public tokenX;
    // Token Y address
    address public tokenY;
    // Maintain State of LPT contract
    bool public initialized;

    constructor(address _factory) {
        factory = _factory;
        initialized = false;
    }


    function initialize(
        address _pair,
        address _tokenX,
        address _tokenY,
        string calldata _name,
        string calldata _symbol
    ) external virtual {
        require(msg.sender == factory);
        require(initialized == false);
        pair = _pair;
        tokenX = _tokenX;
        tokenY = _tokenY;
        name = _name;
        symbol = _symbol;
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
