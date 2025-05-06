// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console } from 'forge-std/Test.sol';
import { AirdopMerkleNFTMarket } from '../src/NFTs/AirdopMerkleNFTMarket.sol';
import { SoToken } from '../src/BaseTokens/ERC20WithPermit.sol';

contract AirdopMerkleNFTMarketTest is Test {
    function setUp() public {}

    function testClaimNFT() public {}

    function testMulticallPermitAndClaim(uint256 buyerIndex) public {}

    // compute merkle root
    function computeMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {}

    // get merkle proof
    function getMerkleProof(address user) public view returns (bytes32[] memory) {}
}
