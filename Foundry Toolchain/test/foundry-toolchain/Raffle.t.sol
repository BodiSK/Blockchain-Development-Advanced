// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {RaffleHouse, Raffle, InvalidTicketPrice, InvalidTime, InvalidRaffleId, RaffleInActive, InvalidAmount, RaffleStillActive, NoTicketsPurchased, NotOwnerOfWinningTicket} from "../../src/foundry-toolchain/RaffleHouse.sol";
import {NFT} from "../../src/foundry-toolchain/NFT.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RaffleHouseInitilizationTest is Test {
    RaffleHouse raffleHouse;

    function setUp() public {
        raffleHouse = new RaffleHouse();
    }

    function test_Initialization() view public {
        assertEq(raffleHouse.raffleCounter(), 0);
    }
}

contract RaffleCreationTest is Test {

    event RaffleCreated(
        address creator,
        uint256 ticketPrice, 
        uint256 startTime, 
        uint256 endTime, 
        string ticketName, 
        string ticketSymbol
    );

    NFT token;
    RaffleHouse raffleHouse;
    string name;
    string symbol;
    uint256 ticketPrice; //in ether
    uint256 startTime;
    uint256 endTime;
    uint256 raffeDuration = 7 days;
    address raffleHouseOwner;
    address raffleCreator;

    function setUp() public {

        name = "Test";
        symbol = "TST";

        ticketPrice = 1 ether;
        startTime = block.timestamp;
        endTime = block.timestamp + raffeDuration;

        raffleHouseOwner = makeAddr("Owner");
        vm.startPrank(raffleHouseOwner);
        raffleHouse = new RaffleHouse();
        vm.stopPrank();

        raffleCreator = makeAddr("Creator");
    }

    function test_RevertIf_TicketInvalidprice() public {
        vm.startPrank(raffleCreator);
        vm.expectRevert(InvalidTicketPrice.selector);
        raffleHouse.createRaffle(0, startTime, endTime, name, symbol);
    }

    function test_RevertIf_InvalidRaffleStartTime() public {
        vm.startPrank(raffleCreator);
        vm.expectRevert(InvalidTime.selector);
        raffleHouse.createRaffle(ticketPrice, 0, endTime, name, symbol);
    }

    function test_RevertIf_InvalidRaffleEndTime() public {
        vm.startPrank(raffleCreator);
        vm.expectRevert(InvalidTime.selector);
        raffleHouse.createRaffle(ticketPrice, startTime, 0, name, symbol);
    }

    function test_RevertIf_InvalidRaffleTimePeriod() public {
        vm.startPrank(raffleCreator);
        vm.expectRevert(InvalidTime.selector);
        raffleHouse.createRaffle(
            ticketPrice,
            startTime,
            startTime - 1,
            name,
            symbol
        );
    }

    function test_CreateRaffle() public {
        vm.startPrank(raffleCreator);
        raffleHouse.createRaffle(ticketPrice, startTime, endTime, name, symbol);
        vm.stopPrank();

        (
            address creator,
            uint256 ticketPrice_,
            uint256 startTime_,
            uint256 endTime_,
            string memory ticketName,
            string memory ticketSymbol,
            address token_,
            uint256 accumulatedPrize,
            uint256 totalTickets,
            bool winnerSelected,
            uint256 winningTicket
        ) = raffleHouse.raffles(0);

        assertEq(raffleHouse.raffleCounter(), 1);

        assertEq(creator, raffleCreator);
        assertEq(ticketPrice_, ticketPrice);
        assertEq(startTime_, startTime);
        assertEq(endTime_, endTime);
        assertEq(ticketName, name);
        assertEq(ticketSymbol, symbol);
        assertEq(accumulatedPrize, 0);
        assertEq(totalTickets, 0);
        assertEq(winnerSelected, false);
    }

    function test_NFTDeploy() public {
        vm.startPrank(raffleCreator);
        raffleHouse.createRaffle(ticketPrice, startTime, endTime, name, symbol);
        vm.stopPrank();

        Raffle memory raffle = raffleHouse.getRaffle(0);


        token = NFT(raffle.token);
        assertEq(token.owner(), address(raffleHouse));
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
    }

    function test_NFTERC721Complience() public {
        vm.startPrank(raffleCreator);
        raffleHouse.createRaffle(ticketPrice, startTime, endTime, name, symbol);
        vm.stopPrank();

        Raffle memory raffle = raffleHouse.getRaffle(0);


        token = NFT(raffle.token);
        assertEq(token.supportsInterface(type(IERC721).interfaceId), true);
    }

    function test_EventEmitOnRaffleCreation() public {
        vm.startPrank(raffleCreator);
        vm.expectEmit(false, false, false, true);

        emit RaffleCreated(
            raffleCreator,
            ticketPrice, 
            startTime, 
            endTime, 
            name, 
            symbol
        );

        raffleHouse.createRaffle(ticketPrice, startTime, endTime, name, symbol);
    }
    
}

contract TicketBuyingTest is Test {

    event TicketBought(
        address buyer,
        uint256 raffleId,
        uint256 ticketId
    );

    NFT token;
    RaffleHouse raffleHouse;
    string name;
    string symbol;
    uint256 ticketPrice; //in ether
    uint256 startTime;
    uint256 endTime;
    uint256 raffeDuration = 7 days;
    address raffleHouseOwner;
    address raffleCreator;
    address ticketBuyerOne;
    address ticketBuyerTwo;

    function setUp() public {

        name = "Test";
        symbol = "TST";

        ticketPrice = 1 ether;
        startTime = block.timestamp;
        endTime = block.timestamp + raffeDuration;

        raffleHouseOwner = makeAddr("Owner");
        vm.startPrank(raffleHouseOwner);
        raffleHouse = new RaffleHouse();
        vm.stopPrank();

        raffleCreator = makeAddr("Creator");
        ticketBuyerOne = makeAddr("TicketBuyerOne");
        ticketBuyerTwo = makeAddr("TicketBuyerTwo");

        vm.deal(ticketBuyerOne, 2 ether);
        vm.deal(ticketBuyerTwo, 2 ether);

        vm.startPrank(raffleCreator);
        raffleHouse.createRaffle(ticketPrice, startTime, endTime, name, symbol);
        vm.stopPrank();
    }

    function test_RevertIf_InvalidRaffleId() public {
        vm.startPrank(ticketBuyerOne);
        vm.expectRevert(InvalidRaffleId.selector);
        raffleHouse.buyTicket(1);
    }

    function test_RevertIf_RaffleEnded() public {
        vm.startPrank(ticketBuyerOne);
        vm.warp(endTime + 1);
        vm.expectRevert(RaffleInActive.selector);
        raffleHouse.buyTicket(0);
    }

    function test_RevertIf_InvalidPriceForTicket() public {
        vm.startPrank(ticketBuyerOne);
        vm.expectRevert(InvalidAmount.selector);
        raffleHouse.buyTicket(0);
    }

    function test_TicketBought() public {
        vm.startPrank(ticketBuyerOne);
        raffleHouse.buyTicket{value: ticketPrice}(0);

        Raffle memory raffle = raffleHouse.getRaffle(0);

        assertEq(raffle.totalTickets, 1);
        assertEq(raffle.accumulatedPrize, ticketPrice);
    }

    function test_MultipleTicketsBought() public {
        vm.startPrank(ticketBuyerOne);
        raffleHouse.buyTicket{value: ticketPrice}(0);
        vm.stopPrank();

        vm.startPrank(ticketBuyerTwo);
        raffleHouse.buyTicket{value: ticketPrice}(0);
        vm.stopPrank();

        Raffle memory raffle = raffleHouse.getRaffle(0);

        assertEq(raffle.totalTickets, 2);
        assertEq(raffle.accumulatedPrize, 2*ticketPrice);
    }

    function test_NFTMint() public {
        vm.startPrank(ticketBuyerOne);
        raffleHouse.buyTicket{value: ticketPrice}(0);

       Raffle memory raffle = raffleHouse.getRaffle(0);


        token = NFT(raffle.token);
        assertEq(token.ownerOf(0), ticketBuyerOne);
    }

    function test_EventEmitOnTicketBought() public {
        vm.startPrank(ticketBuyerOne);
        vm.expectEmit(false, false, false, true);
        emit TicketBought(ticketBuyerOne, 0, 0);
        raffleHouse.buyTicket{value: ticketPrice}(0);
    }
    
}

contract WinnerSelectionTest is Test {

    event WinnerSelected(
        uint256 raffleId,
        uint256 winningTicket
    );

    NFT token;
    RaffleHouse raffleHouse;
    string name;
    string symbol;
    uint256 ticketPrice; //in ether
    uint256 startTime;
    uint256 endTime;
    uint256 raffeDuration = 7 days;
    address raffleHouseOwner;
    address raffleCreator;
    address ticketBuyerOne;
    address ticketBuyerTwo;

    function setUp() public {

        name = "Test";
        symbol = "TST";

        ticketPrice = 1 ether;
        startTime = block.timestamp;
        endTime = block.timestamp + raffeDuration;

        raffleHouseOwner = makeAddr("Owner");
        vm.startPrank(raffleHouseOwner);
        raffleHouse = new RaffleHouse();
        vm.stopPrank();

        raffleCreator = makeAddr("Creator");
        ticketBuyerOne = makeAddr("TicketBuyerOne");
        ticketBuyerTwo = makeAddr("TicketBuyerTwo");

        vm.deal(ticketBuyerOne, 2 ether);
        vm.deal(ticketBuyerTwo, 2 ether);

        vm.startPrank(raffleCreator);
        raffleHouse.createRaffle(ticketPrice, startTime, endTime, name, symbol);
        vm.stopPrank();
    }

    function buyTickets() public {
        vm.startPrank(ticketBuyerOne);
        raffleHouse.buyTicket{value: ticketPrice}(0);
        vm.stopPrank();

        vm.startPrank(ticketBuyerTwo);
        raffleHouse.buyTicket{value: ticketPrice}(0);
        vm.stopPrank();
    }

     function test_RevertIf_InvalidRaffleId() public {
        buyTickets();
        vm.expectRevert(InvalidRaffleId.selector);
        raffleHouse.selectWinner(1);
    }

    function test_RevertIf_RaffleStillActive() public {
        buyTickets();
        vm.expectRevert(RaffleStillActive.selector);
        raffleHouse.selectWinner(0);
    }

    function test_RevertIf_NoTicketsBought() public {
        vm.warp(endTime + 1);
        vm.expectRevert(NoTicketsPurchased.selector);
        raffleHouse.selectWinner(0);
    }

    function test_EmitEventOnWinnerSelection() public {
        buyTickets();
        vm.warp(endTime + 1);
        vm.expectEmit(false, false, false, false);
        emit WinnerSelected(0, 0);
        raffleHouse.selectWinner(0);

        Raffle memory raffle = raffleHouse.getRaffle(0);

        assertEq(raffle.winnerSelected, true);
    }

}

contract ClaimPrizeTest is Test {

    event WinnerClaimedAward(
        uint256 raffleId,
        address winner,
        uint256 prize
    );

    NFT token;
    RaffleHouse raffleHouse;
    string name;
    string symbol;
    uint256 ticketPrice; //in ether
    uint256 startTime;
    uint256 endTime;
    uint256 raffeDuration = 7 days;
    address raffleHouseOwner;
    address raffleCreator;
    address ticketBuyerOne;
    address ticketBuyerTwo;

    function setUp() public {

        name = "Test";
        symbol = "TST";

        ticketPrice = 1 ether;
        startTime = block.timestamp;
        endTime = block.timestamp + raffeDuration;

        raffleHouseOwner = makeAddr("Owner");
        vm.startPrank(raffleHouseOwner);
        raffleHouse = new RaffleHouse();
        vm.stopPrank();

        raffleCreator = makeAddr("Creator");
        ticketBuyerOne = makeAddr("TicketBuyerOne");
        ticketBuyerTwo = makeAddr("TicketBuyerTwo");

        vm.deal(ticketBuyerOne, 2 ether);
        vm.deal(ticketBuyerTwo, 2 ether);

        vm.startPrank(raffleCreator);
        raffleHouse.createRaffle(ticketPrice, startTime, endTime, name, symbol);
        vm.stopPrank();

        vm.startPrank(ticketBuyerOne);
        raffleHouse.buyTicket{value: ticketPrice}(0);
        vm.stopPrank();

        vm.startPrank(ticketBuyerTwo);
        raffleHouse.buyTicket{value: ticketPrice}(0);
        vm.stopPrank();
    }

    function test_RevertIf_InvalidRaffleId() public {
        vm.startPrank(ticketBuyerOne);
        vm.warp(endTime + 1);
        raffleHouse.selectWinner(0);
        vm.expectRevert(InvalidRaffleId.selector);
        raffleHouse.claimPrize(1, 1);
    }

    function test_RevertIf_RaffleStillActive() public {
        vm.startPrank(ticketBuyerOne);
        vm.expectRevert(RaffleStillActive.selector);
        raffleHouse.claimPrize(0, 1);
    }

    function test_revertIf_NotOwnerOfWinningTicket() public {
        vm.warp(endTime + 1);
        raffleHouse.selectWinner(0);
        Raffle memory raffle = raffleHouse.getRaffle(0);

        address winner = NFT(raffle.token).ownerOf(raffle.winningTicket);
        if(winner == ticketBuyerOne) {
            vm.startPrank(ticketBuyerTwo);
        } else {
            vm.startPrank(ticketBuyerOne);
        }
        uint256 winningTicket = raffle.winningTicket;
        vm.expectRevert(NotOwnerOfWinningTicket.selector);
        raffleHouse.claimPrize(0, winningTicket);
    }   

     function test_EmitEventOnCliamPrize() public {
        vm.warp(endTime + 1);
        raffleHouse.selectWinner(0);
        
        Raffle memory raffle = raffleHouse.getRaffle(0);

        address winner = NFT(raffle.token).ownerOf(raffle.winningTicket);
        vm.startPrank(winner);
        vm.expectEmit(false, false, false, true);
        emit WinnerClaimedAward(0, winner, raffle.accumulatedPrize);
        raffleHouse.claimPrize(0, raffle.winningTicket);
    }  

    function test_ClaimPrizeChangeBalance() public {
        vm.warp(endTime + 1);
        raffleHouse.selectWinner(0);
        Raffle memory raffle = raffleHouse.getRaffle(0);

        address winner = NFT(raffle.token).ownerOf(raffle.winningTicket);
        vm.startPrank(winner);
        
        uint256 winnerCurrentBalance = winner.balance;
        raffleHouse.claimPrize(0, raffle.winningTicket);

        assertEq(winner.balance, winnerCurrentBalance + raffle.accumulatedPrize);
    } 

}


contract RaffleLifecycleTest is Test {
    NFT token;
    RaffleHouse raffleHouse;
    string name;
    string symbol;
    uint256 ticketPrice; // in ether
    uint256 startTime;
    uint256 endTime;
    uint256 raffleDuration = 7 days;
    address raffleHouseOwner;
    address raffleCreator;
    address ticketBuyerOne;
    address ticketBuyerTwo;

    function setUp() public {
        name = "Test";
        symbol = "TST";
        ticketPrice = 1 ether;
        startTime = block.timestamp;
        endTime = block.timestamp + raffleDuration;

        raffleHouseOwner = makeAddr("Owner");
        vm.startPrank(raffleHouseOwner);
        raffleHouse = new RaffleHouse();
        vm.stopPrank();

        raffleCreator = makeAddr("Creator");
        ticketBuyerOne = makeAddr("TicketBuyerOne");
        ticketBuyerTwo = makeAddr("TicketBuyerTwo");

        vm.deal(ticketBuyerOne, 2 ether);
        vm.deal(ticketBuyerTwo, 2 ether);
    }
}


