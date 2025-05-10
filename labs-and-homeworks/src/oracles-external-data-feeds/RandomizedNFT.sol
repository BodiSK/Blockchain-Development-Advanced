// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

struct Attributes {
    string species;
    string color;
    string flightSpeed;
    string fireResistance;
}

struct MintRequest {
    address requestSender;
    bool isMinted;
}

error InsufficientAmount();
error AlreadyMinted();

contract RandomizedNFT is ERC721URIStorage, VRFConsumerBaseV2Plus {
    //attribute parametes arrays
    string[] private speciesArray = [
        "Dragon",
        "Unicorn",
        "Phoenix",
        "Griffin",
        "Kraken"
    ];
    string[] private colorArray = ["Red", "Blue", "Green", "Yellow", "Purple"];
    string[] private flightSpeedArray = [
        "Slow",
        "Medium",
        "Fast",
        "Lightspeed"
    ];
    string[] private fireResistanceArray = ["Low", "Medium", "High", "Immune"];

    //VRF parameters
    uint256 immutable SUBSCRIPTION_ID;
    bytes32 immutable GAS_LANE;
    uint32 immutable CALLBACK_GAS_LIMMIT;
    uint16 constant MINIMUM_CONFIRMATIONS = 3;
    uint16 constant NUM_WORDS = 4;

    //NFT parameters
    uint256 private tokenCounter;
    uint256 public immutable MINTING_FEE;

    mapping(uint256 => MintRequest) public mintRequests;

    event MintRequestCreated(
        uint256 indexed requestId,
        address indexed requestSender
    );

    event MintRequestFulfilled(
        uint256 indexed requestId,
        address indexed requestSender
    );

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint32 _callbackGasLimit,
        uint256 _mintingFee
    ) ERC721("RandomizedNFT", "RFT") VRFConsumerBaseV2Plus(_vrfCoordinator) {
        SUBSCRIPTION_ID = _subscriptionId;
        GAS_LANE = _gasLane;
        CALLBACK_GAS_LIMMIT = _callbackGasLimit;
        MINTING_FEE = _mintingFee;
    }

    function requestMint() external payable {
        if (msg.value != MINTING_FEE) revert InsufficientAmount();

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

        mintRequests[requestId] = MintRequest(msg.sender, false);

        emit MintRequestCreated(requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        if (mintRequests[requestId].isMinted) revert AlreadyMinted();

        mintRequests[requestId].isMinted = true;

        Attributes memory attributes = Attributes(
            speciesArray[randomWords[0] % speciesArray.length],
            colorArray[randomWords[1] % colorArray.length],
            flightSpeedArray[randomWords[2] % flightSpeedArray.length],
            fireResistanceArray[randomWords[3] % fireResistanceArray.length]
        );

        uint256 tokenId = tokenCounter++;
        _safeMint(mintRequests[requestId].requestSender, tokenId);

        _setTokenURI(tokenId, attributesToJson(attributes));
        emit MintRequestFulfilled(requestId, mintRequests[requestId].requestSender);
    }

    function attributesToJson(Attributes memory attributes) public pure returns (string memory) {
    string memory json = string(
        abi.encodePacked(
            '{',
                '"name": "Randomized NFT",',
                '"description": "A unique NFT with randomized fantasy creature attributes.",',
                '"image": "https://example.com/image.png",',//todo - add image url
                '"attributes": [',
                    '{ "trait_type": "Species", "value": "', attributes.species, '" },',
                    '{ "trait_type": "Color", "value": "', attributes.color, '" },',
                    '{ "trait_type": "Flight Speed", "value": "', attributes.flightSpeed, '" },',
                    '{ "trait_type": "Fire Resistance", "value": "', attributes.fireResistance, '" }',
                ']',
            '}'
        )
    );

    return string(abi.encodePacked("data:application/json;utf8,", json));
}

}
