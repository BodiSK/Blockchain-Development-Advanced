// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @dev A contract that demonstrates inefficient function implementations
 */

error UserAlreadyRegistered();
error UserNotRegistered();
error ValueAlreadyExists();
error InsufficientBalance();

event ValueAdded(address user, uint256 value);
event Transfer(address from, address to, uint256 amount);

contract FunctionGuzzler {
    uint256 public sum;
    uint256 public valueCount;
    mapping(address => bool) private values;
    mapping(address user => uint256) private usersData;

    function _isRegistered(address user) internal view returns (bool) {
        return (usersData[user] & 1) == 1;
    }

    function registerUser() external {
        if(_isRegistered(msg.sender)){
            revert UserAlreadyRegistered();
        }
        usersData[msg.sender] |= 1; 
    }

    function addValue(uint256 newValue) external {
        if(!_isRegistered(msg.sender)){
            revert UserNotRegistered();
        }

        if(values[msg.sender]) {
            revert ValueAlreadyExists(); 
        }

        sum += newValue;
        valueCount += 1;

        emit ValueAdded(msg.sender, newValue);
    }

    function deposit(uint256 amount) external {
        if(!_isRegistered(msg.sender)){
            revert UserNotRegistered();
        }

        usersData[msg.sender] += amount << 1; // Store amount in the second bit
    }

    function findUser(address user) external view returns (bool) {
        return _isRegistered(user);
    }

    function transfer(address to, uint256 amount) external {
        if(!_isRegistered(msg.sender)) {
            revert UserNotRegistered();
        } 
        
        if(!_isRegistered(to)) {
            revert UserNotRegistered();
        }

        if((usersData[msg.sender] >>1) < amount) {
            revert InsufficientBalance();
        }

        usersData[msg.sender] -= amount << 1;
        usersData[to] += amount << 1;

        emit Transfer(msg.sender, to, amount);
    }

    function getAverageValue() external view returns (uint256) {
        if (valueCount == 0) return 0;

        return sum / valueCount;
    }
}
