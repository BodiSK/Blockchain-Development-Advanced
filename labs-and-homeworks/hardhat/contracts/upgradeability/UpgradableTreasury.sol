// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

error InvalidDepositAmount();

contract TreasuryV1 is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    mapping(address => uint256) public balances;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        string calldata name,
        string calldata symbol
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(initialOwner);

    }

    function deposit() public payable {
        if (msg.value < 0) revert InvalidDepositAmount();
        balances[msg.sender] += msg.value;
    }

    function withdraw(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            ERC20Upgradeable(token).transfer(to, amount);
        }
    }
}

contract TreasuryV2 is TreasuryV1{

    function withdraw(address to) public onlyOwner {
        uint256 amount = address(this).balance;
        payable(to).transfer(amount);

    }
}
