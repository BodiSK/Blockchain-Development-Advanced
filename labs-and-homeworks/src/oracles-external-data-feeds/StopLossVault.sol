// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

struct Vault{
    address owner;
    uint256 amount;
    uint256 stopLossPrice;
    bool isActive;
}

error InsufficientAmount();
error VaultNotActive();
error InvalidVaultId();
error NotOwner();
error WithdrawNotPossible();
error TransferFailed();

contract StopLossVault  {
    AggregatorV3Interface internal priceFeed;

    mapping(uint256 => Vault) public vaults;
    uint256 private vaultCounter;

    event VaultCreated(
        address indexed owner,
        uint256 amount,
        uint256 stopLossPrice
    );

    event FundWithdrawn(
        uint256 indexed vaultId,
        address indexed owner,
        uint256 amount
    );

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function createVault( uint256 _stopLossPrice) external payable {
        if(msg.value == 0) revert InsufficientAmount();


        vaults[vaultCounter++] = Vault({
            owner: msg.sender,
            amount: msg.value,
            stopLossPrice: _stopLossPrice,
            isActive: true
        });

        emit VaultCreated(msg.sender, msg.value, _stopLossPrice);
    }

    function withdraw(uint256 vaultId) external {
        if(vaultId >= vaultCounter) revert InvalidVaultId();

        Vault storage vault = vaults[vaultId];

        if(vault.owner != msg.sender) revert NotOwner();
        if(!vault.isActive) revert VaultNotActive();

        (, int256 price, , , ) = priceFeed.latestRoundData();
        if(price >= int256(vault.stopLossPrice)) revert WithdrawNotPossible();


        vault.isActive = false;
        (bool success, ) = payable(msg.sender).call{value: vault.amount}("");

        if(!success) {
            revert TransferFailed();
        }

        emit FundWithdrawn(vaultId, msg.sender, vault.amount);
    }
}