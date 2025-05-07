// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console } from 'forge-std/Test.sol';
import { AirdopMerkleNFTMarket } from '../src/NFTs/AirdopMerkleNFTMarket.sol';
import { SoToken } from '../src/BaseTokens/ERC20WithPermit.sol';
import '../src/NFTs/MyNFT.sol';

contract AirdopMerkleNFTMarketTest is Test {
    AirdopMerkleNFTMarket public aNftMarket;
    SoNFT public aNFT;

    address public owner;
    address seller;

    uint256 nftId;

    function setUp() public {
        owner = address(this);
        seller = makeAddr('seller');

        aNFT = new SoNFT(owner);
        aNftMarket = new AirdopMerkleNFTMarket(address(aNFT), owner);

        nftId = aNFT.mint(
            seller,
            'https://chocolate-acceptable-hawk-967.mypinata.cloud/ipfs/QmRWFi6XoDFchaZ25g8fTRxY3tc4E289AUQvpUcTqP3w7L'
        );
    }

    function testClaimNFT() public {}

    function testMulticallPermitAndClaim(uint256 buyerIndex) public {}

    // compute merkle root
    function computeMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {}

    // get merkle proof
    function getMerkleProof(address user) public view returns (bytes32[] memory) {}
}
