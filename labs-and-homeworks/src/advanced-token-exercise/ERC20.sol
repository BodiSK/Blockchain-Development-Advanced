// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

error ZeroMerkleRoot();
error InvalidAmount();
error InvalidMerkleProof();
error DeadlineHasPassed();
error InsufficientValue();
error NoSharesLeft();
error AlreadyClaimed();
error NotRelayer();
error SignatureExpired();
error InvalidSignature();

contract AIAgentShare is ERC20, Ownable, EIP712 {
    uint256 public constant MAX_CAP_PLUS_ONE = 50001 * 10 ** 18;
    uint256 public constant MIN_CAP_MINUS_ONE = 99 * 10 ** 18;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant PARTICIPANTS = 260;
    uint256 public constant BITS = 256;
    uint256 public constant RELAYER_FEE = 5 * 10 ** 18;
    bytes32 private constant BUY_AUTHORIZATION_TYPEHASH =
        keccak256(
            "BuyAuthorization(address buyer,uint256 deadline,uint256 amount)"
        );

    bytes32 public immutable merkleRoot;
    uint256 public immutable DDEADLINE = block.timestamp + 10 days;

    uint256 public sharesPool = 5000000 * 10 ** decimals();
    address public relayer;

    uint256[2] private sharesClaimed;

    constructor(
        bytes32 _merkleRoot,
        address _relayer
    )
        ERC20("AIAgentShare", "AIS")
        Ownable(msg.sender)
        EIP712("AIAgentShare", "1")
    {
        require(_merkleRoot != bytes32(0), ZeroMerkleRoot());
        merkleRoot = _merkleRoot;
        relayer = _relayer;
        _mint(msg.sender, 5000000 * 10 ** decimals());
    }

    function setRelayer(address _relayer) external onlyOwner {
        relayer = _relayer;
    }

    function buyWithAuthorization(
        uint256 amount,
        bytes32[] memory proof,
        uint256 index,
        uint256 deadline,
        bytes memory signature
    ) public payable {
        require(msg.sender == relayer, NotRelayer());
        require(
            _verifySignature(msg.sender, deadline, amount, signature),
            InvalidSignature()
        );

        _mint(relayer, RELAYER_FEE);

        _buy(amount, amount-RELAYER_FEE, proof, index, msg.sender);
    }

    function buy(
        uint256 amount,
        bytes32[] memory proof,
        uint256 index
    ) public payable {
        require(msg.value == (amount * PRICE) / 10 ** 18, InsufficientValue());
        _buy(amount,amount, proof, index, msg.sender);
    }

    function _buy(
        uint256 amount,
        uint256 amountToMint,
        bytes32[] memory proof,
        uint256 index,
        address buyer
    ) private {
        require(block.timestamp < DDEADLINE, DeadlineHasPassed());
        require(amount < MAX_CAP_PLUS_ONE, InvalidAmount());
        require(amount > MIN_CAP_MINUS_ONE, InvalidAmount());
        require(isValidProof(proof, index, buyer), InvalidMerkleProof());
        require(!isClaimed(index), AlreadyClaimed());

        _claimShares(index);
        sharesPool -= amount;

        _mint(buyer, amountToMint);
    }

    function isValidProof(
        bytes32[] memory proof,
        uint256 index,
        address buyer
    ) public view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(index, buyer)))
        );

        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 bitIndex = index / BITS;
        uint256 bitPosition = index % BITS;
        uint256 bitMask = 1 << bitPosition;
        return (sharesClaimed[bitIndex] & bitMask) != 0;
    }

    function _claimShares(uint256 index) private {
        uint256 bitIndex = index / BITS;
        uint256 bitPosition = index % BITS;
        uint256 bitMask = 1 << bitPosition;

        sharesClaimed[bitIndex] |= bitMask;
    }

    function _verifySignature(
        address buyer,
        uint256 deadline,
        uint256 amount,
        bytes memory signature
    ) private view returns (bool) {
        require(block.timestamp < deadline, SignatureExpired());

        bytes32 structHash = keccak256(
            abi.encode(BUY_AUTHORIZATION_TYPEHASH, buyer, deadline, amount)
        );

        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, signature);
        return signer == buyer;
    }
}
