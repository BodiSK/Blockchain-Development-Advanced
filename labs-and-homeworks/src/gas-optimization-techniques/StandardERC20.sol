// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/**
 * @dev A standard but gas-inefficient ERC20 implementation
 */

error InsufficientBalance();
error TransferToZeroAddress();
error ApproveToZeroAddress();
error InsufficientAllowance();

contract StandardERC20 {
    uint8 public immutable decimals;
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(msg.sender, _initialSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        if(balanceOf[msg.sender] < value) revert InsufficientBalance();
        if(to == address(0)) revert TransferToZeroAddress();

        balanceOf[msg.sender] -= value;

        unchecked {
            //The total supply of tokens (totalSupply) is usually capped at a value 
            // much smaller than 2^256 - 1 to prevent overflow.
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        if(spender == address(0)) revert ApproveToZeroAddress();

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if(balanceOf[from] < value) revert InsufficientBalance();
        if(allowance[from][msg.sender] < value) revert InsufficientAllowance();
        if(to == address(0)) revert TransferToZeroAddress();

        uint256 allowed = allowance[from][msg.sender];
        if(allowed != type(uint256).max) {
            //If the allowance is not infinite, we need to decrease it by the value transferred.
            allowance[from][msg.sender] = allowed - value;
        }
        balanceOf[from] -= value;

        unchecked {
            //The total supply of tokens (totalSupply) is usually capped at a value 
            // much smaller than 2^256 - 1 to prevent overflow.
            balanceOf[to] += value;
        }
        


        emit Transfer(from, to, value);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        totalSupply += amount;
        unchecked{
            balanceOf[account] += amount;
        }

        emit Transfer(address(0), account, amount);
    }
}
