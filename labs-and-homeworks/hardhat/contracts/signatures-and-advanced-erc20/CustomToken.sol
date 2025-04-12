// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {console} from "hardhat/console.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

error PermitExpired();
error InvalidSignature();


contract CustomToken is ERC20, IERC20Permit, EIP712 {

    bytes32 private constant PERMIT_TYPEHASH = 
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address=> uint256) private _nonces;

    constructor() ERC20("CustomContract", "CC") EIP712("CustomContract", "1") {
    }


    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override{
        if(deadline < block.timestamp) revert PermitExpired();
        bytes32 structHash = keccak256(abi.encode(
            PERMIT_TYPEHASH,
            owner,
            spender,
            value,
            _useNonce(owner),
            deadline
        ));

        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ecrecover(digest, v, r, s);

        if(signer != owner) revert InvalidSignature();
        _approve(owner, spender, value);
    }


    function _useNonce(address owner) private returns (uint256) {
        unchecked {
            return _nonces[owner]++;
        }
    }

    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner];
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

}