// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error AuthorizationExpired();
error InvalidSignature();
error AuthorizationUsed();

contract AdvancedToken is ERC20Permit {
    mapping(bytes32 => bool) private usedAllowances;

    bytes32 public TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        keccak256(
            "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
        );

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) ERC20Permit(name) {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp < validAfter || block.timestamp > validBefore) {
            revert AuthorizationExpired();
        }

        bytes32 authorizationHash = _getAuthorizationHash(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce
        );

        if (usedAllowances[authorizationHash]) {
            revert AuthorizationUsed();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
                from,
                to,
                value,
                validAfter,
                validBefore,
                nonce
            )
        );

        bytes32 digest = EIP712._hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, v, r, s);
        if (signer != from) {
            revert InvalidSignature();
        }


        usedAllowances[authorizationHash] = true;
        _transfer(from, to, value);
    }

    function _getAuthorizationHash(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(from, to, value, validAfter, validBefore, nonce)
            );
    }
}
