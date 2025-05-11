// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error InvalidRatio();
error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error InvalidToken();
error InsufficientLiquidityForSwap();

contract CPAMM is ERC20 {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public constant FEE = 3;

    constructor(address _token0, address _token1) ERC20("CPAMM", "CPAMM") {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function addLiquidity(uint256 amount0, uint256 amount1) external {
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        uint256 shares;
        if (reserve0 > 0 || reserve1 > 0) {
            if (reserve0 * amount1 != reserve1 * amount0) revert InvalidRatio();

            shares = _min(
                (amount0 * this.totalSupply()) / reserve0,
                (amount1 * this.totalSupply()) / reserve1
            );
        } else {
            shares = _sqrt(amount0 * amount1);
        }

        if (shares == 0) revert InsufficientLiquidityMinted();
        _mint(msg.sender, shares);

        _updateReserves(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    function removeLiquidity(uint256 shares) external {

        uint256 amount0 = (shares * reserve0) / this.totalSupply();
        uint256 amount1 = (shares * reserve1) / this.totalSupply();

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();
        
        _burn(msg.sender, shares);


        _updateReserves(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }

    function swap(uint256 amountIn, address tokenIn) external {

        if (tokenIn != address(token0) && tokenIn != address(token1))
            revert InvalidToken();

        bool isToken0 = tokenIn == address(token0);

        (IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) = isToken0
            ? (token1, reserve0, reserve1)
            : (token0, reserve1, reserve0);

        uint256 amountInWithFee = (amountIn * (1000 - FEE)) / 1000;
        uint256 amount0utWithFee = (amountInWithFee * reserveOut) /
            (reserveIn + amountInWithFee);

        if (amount0utWithFee == 0) revert InsufficientLiquidityForSwap();

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amount0utWithFee);

        _updateReserves(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _updateReserves(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
