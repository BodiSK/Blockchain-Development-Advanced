// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

enum Direction {
    UP,
    DOWN
}

struct Round {
    uint256 lockTime;
    uint256 endTime;
    int256 startPrice;
    int256 endPrice;
    uint256 totalUp;
    uint256 totalDown;
    bool resolved;
}

struct Bet {
    Direction direction;
    uint256 amount;
    bool claimed;
}

error InvalidLockTime();
error InvalidDuration();
error InvalidRoundId();
error BettingWindowClosed();
error InvalidBetAmount();
error RoundAlreadyResolved();
error BetAlreadyPlaced();
error BettingWindowOpened();
error BetAlreadyClaimed();
error RoundStillActive();
error ClaimTransferFailed();

contract PricePrediction is Ownable {
    AggregatorV3Interface internal priceFeed;

    event RoundStarted(
        uint256 roundId,
        uint256 lockTime,
        uint256 endTime,
        int256 price
    );
    event BetPlaced(
        uint256 roundId,
        address indexed player,
        Direction direction,
        uint256 amount
    );

    event RoundResolved(
        uint256 roundId,
        int256 endPrice
    );

    event PayoutClaimed(
        uint256 roundId,
        address indexed player,
        uint256 amount
    );

    uint256 private roundCounter;

    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(address => Bet)) public bets;

    constructor(address _priceFeed) Ownable(msg.sender) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function startRound(
        uint256 _lockTime,
        uint256 roundDuration
    ) external onlyOwner {
        if (_lockTime < block.timestamp) revert InvalidLockTime();
        if (roundDuration < _lockTime) revert InvalidDuration();

        roundCounter++;

        int256 price = getPrice();

        uint256 lockTime = block.timestamp + _lockTime;
        uint256 endTime = block.timestamp + roundDuration;

        rounds[roundCounter] = Round({
            lockTime: lockTime,
            endTime: endTime,
            startPrice: price,
            endPrice: 0,
            totalUp: 0,
            totalDown: 0,
            resolved: false
        });

        emit RoundStarted(roundCounter, lockTime, endTime, price);
    }

    function bet(uint256 roundId, Direction direction) external payable {
        if (roundId > roundCounter) revert InvalidRoundId();

        Round storage round = rounds[roundId];

        if (block.timestamp > round.lockTime) revert BettingWindowClosed();
        if (round.resolved) revert RoundAlreadyResolved();
        if (msg.value == 0) revert InvalidBetAmount();
        if (bets[roundId][msg.sender].amount > 0) revert BetAlreadyPlaced();

        bets[roundId][msg.sender] = Bet({
            direction: direction,
            amount: msg.value,
            claimed: false
        });

        if (direction == Direction.UP) {
            round.totalUp += msg.value;
        } else {
            round.totalDown += msg.value;
        }

        emit BetPlaced(roundId, msg.sender, direction, msg.value);
    }

    function resolveRound(uint256 roundId) external onlyOwner {
        if (roundId > roundCounter) revert InvalidRoundId();

        Round storage round = rounds[roundId];

        if (block.timestamp < round.endTime) revert BettingWindowOpened();
        if (round.resolved) revert RoundAlreadyResolved();

        int256 price = getPrice();
        round.endPrice = price;
        round.resolved = true;

        emit RoundResolved(roundId, price); 
    }

    function claim(uint256 roundId) external {
        if (roundId > roundCounter) revert InvalidRoundId();

        Round storage round = rounds[roundId];
        Bet storage playerBet = bets[roundId][msg.sender];

        if (playerBet.claimed) revert BetAlreadyClaimed();
        if (!round.resolved) revert RoundStillActive();

        playerBet.claimed = true;

        uint256 payout = 0;

        if(round.startPrice == round.endPrice) {
            (bool success, ) = msg.sender.call{value: playerBet.amount}("");
            if (!success) {
                revert ClaimTransferFailed();
            }
            emit PayoutClaimed(roundId, msg.sender, playerBet.amount);
            return;
        }

        Direction winningDirection = round.endPrice > round.startPrice
            ? Direction.UP
            : Direction.DOWN;

        uint256 totalPool = round.totalUp + round.totalDown;
        uint256 winningPool = winningDirection == Direction.UP
            ? round.totalUp
            : round.totalDown;

        if(playerBet.direction == winningDirection) {
            payout = (playerBet.amount * totalPool) / winningPool;
        } 

        (bool refundSuccess, ) = msg.sender.call{value: payout}("");
            if (!refundSuccess) {
                revert ClaimTransferFailed();
            }
        emit PayoutClaimed(roundId, msg.sender, payout);
    }


    function getPrice() internal view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}
