// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.13;

// import {SafeERC20, IERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./RBTWrapper.sol";
import "./orderEngine.sol";

contract orderPair is RBTWrapper, orderEngine {
    using SafeERC20 for IERC20;

    IERC20 public immutable token1; //WETH
    IERC20 public immutable token2; //DAI
    uint32 constant maxFee = 250;

    error amountLessThanMin();
    error noOrderForSuchPrice();
    error NoAmountsForPrice();
    error amountGreaterThanPriceQty();

    constructor(address _token1, address _token2) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }

    function makeBuyOrder(uint160 price, uint160 amountInToken2) public {
        // if(amount < 10 gwei) {
        //     revert amountLessThanMin();
        // }
        if (!RBTWrapper.getExists(price, 1)) {
            RBTWrapper.addOrder(price, 1);
        }
        setOrder(price, amountInToken2, 1);
    }

    function makeSellOrder(uint160 price, uint160 amountInToken1) public {
        // if(amount < 10 gwei) {
        //     revert amountLessThanMin();
        // }
        if (!RBTWrapper.getExists(price, 2)) {
            RBTWrapper.addOrder(price, 2);
        }
        orderEngine.setOrder(price, amountInToken1, 2);

        // token1.safeTransferFrom(msg.sender, address(this), amountInToken1);
    }

    function fullFIllBuyOrder(uint160 price, uint32 orderId) public {
        if (!RBTWrapper.getExists(price, 1)) {
            revert noOrderForSuchPrice();
        }
        (uint160 _orderAmount, uint8 _side, address _maker) = orderEngine.getOrder(orderId);
        uint160 amount1Out = (_orderAmount / price) * 1e18;
        token1.safeTransferFrom(msg.sender, _maker, amount1Out);
        token2.safeTransferFrom(_maker, msg.sender, _orderAmount);

        orderEngine.removeOrder(orderId, price, _side);
    }

    function fullFIllSellOrder(uint160 price, uint32 orderId) public {
        if (!RBTWrapper.getExists(price, sellSideConst)) {
            revert noOrderForSuchPrice();
        }
        (uint160 _orderAmount, uint8 _side, address _maker) = orderEngine.getOrder(orderId);
        uint160 amount2Out = (_orderAmount * price) / 1e18;
        token2.safeTransferFrom(msg.sender, _maker, _orderAmount);
        token1.safeTransferFrom(_maker, msg.sender, amount2Out);
        orderEngine.removeOrder(orderId, price, _side);
    }
}
