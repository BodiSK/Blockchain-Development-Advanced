// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract B {
    uint256 num;
    address sender;
    uint256 value;

    function setVars(uint256 _num) external payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract A {
    uint256 num;
    address sender;
    uint256 value;

    address contractB;

    constructor(address _B) {
        contractB = _B;
    }

    function setVars(uint256 _num) external payable {
        (bool ok, ) = contractB.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        require(ok, "delegatecall failed");

    }
}
