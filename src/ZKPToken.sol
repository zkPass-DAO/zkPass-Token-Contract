// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title ZKPToken
 * @dev This contract is the implementation of the ZKPToken contract.
 */
contract ZKPToken is OFT, ERC20Permit, ERC20Votes {
    event InitialSupplyMinted(
        address indexed treasury,
        uint256 amount,
        uint256 supplyCap
    );

    uint256 public immutable SUPPLY_CAP = 1_000_000_000 * 10 ** 18; // Set on all chains

    /// @dev Constructor
    /// @param lzEndpoint The LayerZero endpoint address
    /// @param owner The owner of the contract
    /// @param multiSigTreasury The multi-signature treasury address
    /// @param mintingChainId The chain ID where the token is minted
    constructor(
        address lzEndpoint,
        address owner,
        address multiSigTreasury,
        uint256 mintingChainId
    )
        OFT("zkPass", "ZKP", lzEndpoint, owner)
        Ownable(owner)
        ERC20Permit("zkPass")
    {
        require(lzEndpoint != address(0), "LZEndpoint cannot be zero address");
        require(owner != address(0), "Owner cannot be zero address");
        require(
            multiSigTreasury != address(0),
            "MultiSigTreasury cannot be zero address"
        );

        if (block.chainid == mintingChainId) {
            // Mint the initial supply to the treasury
            _mint(multiSigTreasury, SUPPLY_CAP);

            emit InitialSupplyMinted(multiSigTreasury, SUPPLY_CAP, SUPPLY_CAP);
        }
    }

    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 _srcEid
    ) internal override returns (uint256) {
        require(_to != address(0), "ZKPToken: cannot bridge to zero address");
        return super._credit(_to, _amountLD, _srcEid);
    }

    function _maxSupply() internal view override returns (uint256) {
        return SUPPLY_CAP;
    }

    function renounceOwnership() public override {
        revert("ZKPToken: renouncing ownership is disabled");
    }

    function invalidatePermit() external {
        _useNonce(msg.sender);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    function nonces(
        address owner
    ) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
