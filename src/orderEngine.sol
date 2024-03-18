// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "solady/utils/LibSort.sol";

contract orderEngine {
    using LibSort for uint256[];

    mapping(uint32 => Order) public orders;
    mapping(uint160 => uint256[]) public buyOrdersAtPrice;
    mapping(uint160 => uint256[]) public sellOrdersAtPrice;

    struct Order {
        uint160 amount;
        uint8 side;
        address maker;
    }

    uint32 public orderCounter;
    uint8 public constant buySideConst = 1;
    uint8 public constant sellSideConst = 2;

    error amountLessThanMinmuim();
    error InvalidOrderSide();
    error maxOrdersPerPrice();

    constructor() {
        orderCounter++;
    }

    function setOrder(uint160 _price, uint160 _amount, uint8 _ordeSide) public {
        if (_amount < 100000 gwei) {
            //i.e amount must be >= 100000000000000 wei or 0.0001 ETH for short
            revert amountLessThanMinmuim();
        }
        if (_ordeSide == buySideConst) {
            setBuyOrder(_price, _amount);
        } else if (_ordeSide == sellSideConst) {
            setSellOrder(_price, _amount);
        } else {
            revert InvalidOrderSide();
        }
    }

    function setBuyOrder(uint160 _price, uint160 _amount) internal {
        uint256[] memory arr = buyOrdersAtPrice[_price];
        uint32 len = uint32(arr.length);
        if (len == 10) {
            //if 10, check if first index is [0], if yes, insert order in that location

            if (arr[0] == 0) {
                arr[0] = orderCounter;
                LibSort.insertionSort(arr);
                buyOrdersAtPrice[_price] = arr;

                storeOrder(_amount, msg.sender, buySideConst);
            } else {
                revert maxOrdersPerPrice();
            }
        } else if (len < 10) {
            buyOrdersAtPrice[_price].push(orderCounter);
            storeOrder(_amount, msg.sender, buySideConst);
        } else {
            revert maxOrdersPerPrice();
        }
    }

    function setSellOrder(uint160 _price, uint160 _amount) internal {
        uint256[] memory arr = sellOrdersAtPrice[_price];
        uint32 len = uint32(arr.length);
        if (len == 10) {
            //if 10, check if first index is [0], if yes, insert order in that location
            //if there is 0 index, and it is not 0, call sortArray manually to get 0 at the [0] index
            if (arr[0] == 0) {
                arr[0] = orderCounter;
                LibSort.insertionSort(arr);
                sellOrdersAtPrice[_price] = arr;

                storeOrder(_amount, msg.sender, sellSideConst);
            } else {
                revert maxOrdersPerPrice();
                //if len is 10 and no 0 orders, place a new order on
                //a price -1 decimal of current price or +1 decimal
            }
        } else if (len < 10) {
            sellOrdersAtPrice[_price].push(orderCounter);
            storeOrder(_amount, msg.sender, sellSideConst);
        } else {
            revert maxOrdersPerPrice(); //len > 10, max 10 orders
        }
    }

    function storeOrder(uint160 _amount, address _maker, uint8 orderSide) internal {
        Order storage order = orders[orderCounter];
        order.amount = _amount;
        order.maker = _maker;
        order.side = orderSide;
        orderCounter++;
    }

    function getOrder(uint32 _orderID) public view returns (uint160 _orderAmount, uint8 _side, address _maker) {
        Order memory order = orders[_orderID];
        _orderAmount = order.amount;
        _maker = order.maker;
        _side = order.side;

        return (_orderAmount, _side, _maker);
    }

    function removeOrder(uint32 _orderID, uint160 _price, uint8 _orderSide) public {
        if (_orderSide == buySideConst) {
            uint256[] memory arr = buyOrdersAtPrice[_price];
            (bool exists, uint256 index) = LibSort.searchSorted(arr, _orderID);
            require(exists, "does not exist");
            delete buyOrdersAtPrice[_price][index];
        } else if (_orderSide == sellSideConst) {
            uint256[] memory arr = sellOrdersAtPrice[_price];
            (bool exists, uint256 index) = LibSort.searchSorted(arr, _orderID);
            require(exists, "does not exist");
            delete sellOrdersAtPrice[_price][index];
        } else {
            revert InvalidOrderSide();
        }
    }

    function removeOrderAtIndex(uint8 _index, uint160 _price, uint8 _orderSide) public {
        uint256 orderID;
        if (_orderSide == buySideConst) {
            orderID = buyOrdersAtPrice[_price][_index];
            delete buyOrdersAtPrice[_price][_index];
        } else if (_orderSide == sellSideConst) {
            orderID = sellOrdersAtPrice[_price][_index];
            delete sellOrdersAtPrice[_price][_index];
        }
        if (orderID == 0) {
            revert(); //indexOutOfBounds
        }
    }

    function sortArr(uint160 _price, uint8 _orderSide) public {
        // call this only when an index[i] of returnArr() is 0 or multiple, and is not at index[0] unless multiple, then it's fine
        uint256[] memory arr;
        if (_orderSide == buySideConst) {
            arr = buyOrdersAtPrice[_price];
            LibSort.insertionSort(arr);
            // if(arr[1] == 0){
            //     LibSort.uniquifySorted(arr);
            // }
            buyOrdersAtPrice[_price] = arr;
        } else if (_orderSide == sellSideConst) {
            arr = sellOrdersAtPrice[_price];
            LibSort.insertionSort(arr);
            // if(arr[1] == 0){
            //     LibSort.uniquifySorted(arr);
            // }
            sellOrdersAtPrice[_price] = arr;
        }
    }

    function returnArr(uint160 _price, uint8 _orderSide) public view returns (uint256[] memory arr) {
        if (_orderSide == buySideConst) {
            arr = buyOrdersAtPrice[_price];
        } else if (_orderSide == sellSideConst) {
            arr = sellOrdersAtPrice[_price];
        }
        return arr;
    }

    function editMinusOrderAmount(uint160 _price, uint8 _orderID, uint160 _amtToRemove) public  {
        (uint160 _orderAmount, uint8 _side, address _maker) = getOrder(_orderID);
        if(msg.sender != _maker) {
            revert();
        }
        uint160 newAmount =_orderAmount - _amtToRemove;
        orders[_orderID].amount = newAmount;
        
        if (newAmount == 0) {
            removeOrder(_orderID, _price, _side);
        }
    }

    function editPlusOrderAmount(uint8 _orderID, uint160 _amtToAdd) public  {
        (uint160 _orderAmount, , address _maker) = getOrder(_orderID);
        if(msg.sender != _maker) {
            revert();
        }
        orders[_orderID].amount = _orderAmount + _amtToAdd;
    }
}