// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

error InvalidEntryFee();
error RaffleNotOpen();
error NotEnoughPlayers();
error MinimalTimeIntervalForPlayNotPassed();
error TransferFailed();

contract SmartContractLottery is VRFConsumerBaseV2Plus {
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint256 immutable SUBSCRIPTION_ID;
    bytes32 immutable GAS_LANE;
    uint32 immutable CALLBACK_GAS_LIMMIT;
    uint16 constant MINIMUM_CONFIRMATIONS = 3;
    uint16 constant NUM_WORDS = 1;

    RaffleState public raffleState;
    uint256 public constant ENTRANCE_FEE = 0.01 ether;
    uint256 public constant MINIMAL_TIME_INTERVAL = 30 minutes;
    uint256 public startedAt;
    address[] public players;

    event RaffleEntered(address indexed player);
    event WinnerRequested(uint256 indexed requestId);

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        SUBSCRIPTION_ID = _subscriptionId;
        GAS_LANE = _gasLane;
        CALLBACK_GAS_LIMMIT = _callbackGasLimit;
        raffleState = RaffleState.OPEN;
        startedAt = block.timestamp;
    }

    function enterRaffle() external payable {
        if (raffleState != RaffleState.OPEN) revert RaffleNotOpen();

        if (msg.value != ENTRANCE_FEE) revert InvalidEntryFee();

        players.push(msg.sender);

        emit RaffleEntered(msg.sender);
    }


    function requestRandomWinner() external  {
        if (block.timestamp - startedAt < MINIMAL_TIME_INTERVAL)
            revert MinimalTimeIntervalForPlayNotPassed();

        if (raffleState != RaffleState.OPEN) revert RaffleNotOpen();

        if (players.length == 0 || address(this).balance == 0) revert NotEnoughPlayers();

        raffleState = RaffleState.CALCULATING;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: GAS_LANE,
                subId: SUBSCRIPTION_ID,
                requestConfirmations: MINIMUM_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            })
        );

        emit WinnerRequested(requestId);
    }

    function fulfillRandomWords(
        uint256 ,
        uint256[] calldata randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % players.length;
        address winner = players[winnerIndex];

        // Reset the raffle
        players = new address[](0);
        raffleState = RaffleState.OPEN;
        startedAt = block.timestamp;

        uint256 totalAmountCollected = address(this).balance;
        (bool success, ) = winner.call{value: totalAmountCollected}("");
        if(!success) {
            revert TransferFailed();
        }   

    }
}
