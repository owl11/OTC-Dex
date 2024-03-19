// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/orderPair.sol";
import "./mock/mockToken.sol";

contract orderPairTest is Test {
    orderPair pair;
    mockToken token1;
    mockToken token2;
    address USER1 = address(1);
    address USER2 = address(2);

    function setUp() public {
        token1 = new mockToken(USER1);
        token2 = new mockToken(USER2);
        pair = new orderPair(address(token1), address(token2));
    }

    function testmakeBuyOrder() public {
        vm.startPrank(USER2);
        token2.approve(address(pair), 1 ether);
        pair.makeBuyOrder(1 ether, 1 ether);
    }

    function testmakeSellOrder() public {
        vm.startPrank(USER1);
        token1.approve(address(pair), 1 ether);
        pair.makeSellOrder(1 ether, 1 ether);
    }

    modifier buyOrderMade() {
        vm.startPrank(USER2);
        token2.approve(address(pair), 2000 ether);
        pair.makeBuyOrder(2000 ether, 2000 ether);
        _;
    }

    function testFullFillOrderBuySide() public buyOrderMade {
        vm.startPrank(USER1);
        token1.approve(address(pair), 1 ether);
        pair.fullFIllBuyOrder(2000 ether, 1);
        console2.log(token2.balanceOf(USER1));
        console2.log(token1.balanceOf(USER2));
    }

    modifier sellOrderMade() {
        vm.startPrank(USER1);
        token1.approve(address(pair), 2000 ether);
        pair.makeSellOrder(2000 ether, 1 ether);
        _;
    }

    function testFullFillOrderSellSide() public sellOrderMade {
        vm.startPrank(USER2);
        token2.approve(address(pair), 1 ether);
        pair.fullFIllSellOrder(2000 ether, 1);
        console2.log(token2.balanceOf(USER1));
        console2.log(token1.balanceOf(USER2));
    }
}
