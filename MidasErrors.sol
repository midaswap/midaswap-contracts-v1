// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/IMidasPair721.sol";

/** Router errors */

error Router__WrongPair();
error Router__WrongAmount();
error Router__Expired();

/** MidasPair721 errors */

error MidasPair__AddressWrong();
error MidasPair__RangeWrong();
error MidasPair__AmountInWrong();
error MidasPair__BinSequenceWrong();
error MidasPair__LengthWrong();
error MidasPair__NFTOwnershipWrong();
error MidasPair__PriceOverflow();
