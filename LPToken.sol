// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC721} from "../libraries/ERC721.sol";
import {Strings} from "../libraries/Strings.sol";

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

    constructor(string memory _name, string memory _symbol, address _factory, address _tokenX, address _tokenY)
        ERC721(_name, _symbol)
    {
        factory = _factory;
        tokenX = _tokenX;
        tokenY = _tokenY;
    }

    modifier onlyPair() {
        require(msg.sender == pair);
        _;
    }

    function initialize(address _pair) external virtual {
        require(msg.sender == factory);
        pair = _pair;
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

}
