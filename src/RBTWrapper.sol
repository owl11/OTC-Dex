// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "solady/utils/RedBlackTreeLib.sol";

contract RBTWrapper {
    using RedBlackTreeLib for RedBlackTreeLib.Tree;

    RedBlackTreeLib.Tree private sellOrderBook;
    RedBlackTreeLib.Tree private buyOrderBook;

    uint32 orderCount = 1;

    // Add a new order to the order book
    function addOrder(uint160 _price, uint8 _orderSide) internal {
        // uint160 combinedKey = priceAndIdPadder(thisOrder, _price);
        if (_orderSide == 1) {
            buyOrderBook.insert(_price);
        } else if (_orderSide == 2) {
            sellOrderBook.insert(_price);
        } else {
            revert();
        }
    }

    function priceAndIdPadder(uint32 _orderCount, uint160 _price) public pure returns (uint160 combinedKey) {
        assembly {
            let shiftedPrice := shl(80, _price)
            combinedKey := or(shiftedPrice, _orderCount)
        }
        return combinedKey;
    }

    function getPrices(uint8 _orderSide) public view returns (uint256[] memory ordersArr) {
        if (_orderSide == 1) {
            ordersArr = buyOrderBook.values();
        } else {
            ordersArr = sellOrderBook.values();
        }
        return ordersArr;
    }

    function getNearest(uint256 _needle, uint8 _orderSide) public view returns (bytes32 _key) {
        if (_orderSide == 1) {
            _key = buyOrderBook.nearest(_needle);
        } else {
            _key = sellOrderBook.nearest(_needle);
        }
        return _key;
    }

    function getNearestBefore(uint256 _needle, uint8 _orderSide) public view returns (bytes32 _key) {
        if (_orderSide == 1) {
            _key = buyOrderBook.nearestBefore(_needle); //dont use for currentPrice I.E last()
        } else {
            _key = sellOrderBook.nearestBefore(_needle);
        }
        return _key;
    }

    function getNearestAfter(uint256 _needle, uint8 _orderSide) public view returns (bytes32 _key) {
        if (_orderSide == 1) {
            _key = buyOrderBook.nearestAfter(_needle);
        } else {
            _key = sellOrderBook.nearestAfter(_needle); //dont use for currentPrice I.E first()
        }
        return _key;
    }

    function getExists(uint256 _value, uint8 _orderSide) public view returns (bool _exists) {
        if (_orderSide == 1) {
            _exists = buyOrderBook.exists(_value);
        } else if (_orderSide == 2) {
            _exists = sellOrderBook.exists(_value);
        } else {
            revert();
        }
        return _exists;
    }

    function getFirst(uint8 _orderSide) public view returns (bytes32 _firstPtr) {
        if (_orderSide == 1) {
            _firstPtr = buyOrderBook.first();
        } else if (_orderSide == 2) {
            _firstPtr = sellOrderBook.first();
        } else {
            revert();
        }
        return _firstPtr;
    }

    function getLast(uint8 _orderSide) public view returns (bytes32 _lastPtr) {
        if (_orderSide == 1) {
            _lastPtr = buyOrderBook.last();
        } else if (_orderSide == 2) {
            _lastPtr = sellOrderBook.last();
        } else {
            revert();
        }
        return _lastPtr;
    }

    function getValue(bytes32 _ptr) public view returns (uint256) {
        return RedBlackTreeLib.value(_ptr);
    }

    function removeValue(uint256 _value, uint8 _orderSide) public {
        if (_orderSide == 1) {
            buyOrderBook.remove(_value);
        } else if (_orderSide == 2) {
            sellOrderBook.remove(_value);
        } else {
            revert();
        }
    }

    function getNextNonEqualPrice(uint8 _orderSide) public view returns (uint256[5] memory percentageArray) {
        uint256[] memory five_first_values;
        // if (five_first_values.length < 5) {
        //     revert(); //TODO add custom error ID
        // }
        if (_orderSide == 1) {
            five_first_values = getPrices(_orderSide);
            for (uint256 i; i < 5; i++) {
                percentageArray[i] = five_first_values[i + 1] - five_first_values[i];
            }
        } else if (_orderSide == 2) {
            five_first_values = getPrices(_orderSide);
            uint256 len = sellOrderBook.size();
            uint256 lenMinmusFive = len - 5;
            for (uint256 i = 0; len > lenMinmusFive; len--) {
                percentageArray[i] = five_first_values[len - 1] - five_first_values[len - 2];
                i++;
            }
            return percentageArray;
        }
    }

    function getOrderBookPrice(uint256 _needle, uint8 _orderSide) public view returns (bytes32 _findPtr) {
        if (_orderSide == 1) {
            _findPtr = buyOrderBook.find(_needle);
        } else if (_orderSide == 2) {
            _findPtr = sellOrderBook.find(_needle);
        } else {
            revert();
        }
        return _findPtr;
    }
}