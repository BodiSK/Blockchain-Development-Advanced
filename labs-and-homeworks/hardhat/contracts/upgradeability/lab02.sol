// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract BaseNFTImplementation is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        string calldata tokenName,
        string calldata tokenSymbol
    ) public initializer {
        __ERC721_init(tokenName, tokenSymbol);
        __Ownable_init(initialOwner);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}

contract TokenFactory  {
    address public immutable implementation;
    mapping(address => address[]) public collections;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createNFTCollection(string calldata name, string calldata symbol) external {
        address clone = Clones.clone(implementation);
        BaseNFTImplementation(clone).initialize(
            msg.sender,
            name,
            symbol
        );
        collections[msg.sender].push(clone);
    }
}
