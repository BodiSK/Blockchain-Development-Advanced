// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFT} from "./NFT.sol";

error InvalidTicketPrice();
error InvalidTime();
error InvalidRaffleId();
error RaffleInActive();
error InvalidAmount();
error RaffleStillActive();
error NoTicketsPurchased();
error NotOwnerOfWinningTicket();
struct Raffle {
        address creator;
        uint256 ticketPrice;
        uint256 startTime;
        uint256 endTime;
        string ticketName;
        string ticketSymbol;
        address token;
        uint256 accumulatedPrize;
        uint256 totalTickets;
        bool winnerSelected;
        uint256 winningTicket;
}

contract RaffleHouse {

    event RaffleCreated(
        address creator,
        uint256 ticketPrice, 
        uint256 startTime, 
        uint256 endTime, 
        string ticketName, 
        string ticketSymbol
    );

    event TicketBought(
        address buyer,
        uint256 raffleId,
        uint256 ticketId
    );

    event WinnerSelected(
        uint256 raffleId,
        uint256 winningTicket
    );

    event WinnerClaimedAward(
        uint256 raffleId,
        address winner,
        uint256 prize
    );

    uint256 public raffleCounter;

    //mapping is by tokenId
    mapping(uint256 => Raffle) public raffles;

    function createRaffle(
        uint256 ticketPrice,
        uint256 startTime,
        uint256 endTime,
        string calldata ticketName,
        string calldata ticketSymbol
    ) public {

        if(ticketPrice == 0) revert InvalidTicketPrice();
        if(startTime<=0 || startTime>=endTime ) revert InvalidTime();

        NFT nft = new NFT(address(this), ticketName, ticketSymbol);

        uint256 raffleId = raffleCounter++;
        raffles[raffleId] = Raffle({
            creator: msg.sender,
            ticketPrice: ticketPrice,
            startTime: startTime,
            endTime: endTime,
            ticketName: ticketName,
            ticketSymbol: ticketSymbol,
            token: address(nft),
            accumulatedPrize: 0,
            totalTickets: 0,
            winnerSelected: false,
            winningTicket: 0
        });

        emit RaffleCreated(msg.sender, ticketPrice, startTime, endTime, ticketName, ticketSymbol);
    }

    function buyTicket(
        uint256 raffleId
    ) public payable returns (uint256) {
        if(raffleId>=raffleCounter) revert InvalidRaffleId();
    
        Raffle storage raffle = raffles[raffleId];
        if(raffle.startTime > block.timestamp 
            ||raffle.endTime < block.timestamp 
            || raffle.winnerSelected) revert RaffleInActive();

        if(msg.value != raffle.ticketPrice) revert InvalidAmount();

        NFT nft = NFT(raffle.token);
        uint256 ticketId = nft.safeMint(msg.sender);

        raffle.totalTickets++;
        raffle.accumulatedPrize += msg.value;

        emit TicketBought(msg.sender, raffleId, ticketId);
        return ticketId;
    }

    function selectWinner(uint256 raffleId) public {
        if(raffleId>=raffleCounter) revert InvalidRaffleId();

        Raffle storage raffle = raffles[raffleId];
        if(block.timestamp < raffle.endTime) revert RaffleStillActive();
        if(raffle.totalTickets == 0) revert NoTicketsPurchased();

        uint256 winningTicket = 
            uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, raffle.totalTickets))) % raffle.totalTickets;

        raffle.winnerSelected = true;
        raffle.winningTicket = winningTicket;

        emit WinnerSelected(raffleId, winningTicket);
    }

    function claimPrize(uint256 raffleId, uint256 ticketId) public {
        if(raffleId>=raffleCounter) revert InvalidRaffleId();

        Raffle storage raffle = raffles[raffleId];
        if(!raffle.winnerSelected) revert RaffleStillActive();

        if(raffle.winningTicket != ticketId || NFT(raffle.token).ownerOf(ticketId) != msg.sender) revert NotOwnerOfWinningTicket();

        payable(msg.sender).transfer(raffle.accumulatedPrize);
        emit WinnerClaimedAward(raffleId, msg.sender, raffle.accumulatedPrize);
        
    }

    function getRaffle(uint256 raffleId) public view returns (Raffle memory) {
        if(raffleId>=raffleCounter) revert InvalidRaffleId();
        return raffles[raffleId];
    }
    
}