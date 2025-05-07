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

    address internal buyer1;
    address internal buyer2;
    uint256 internal buyer1PrivateKey;
    uint256 internal buyer2PrivateKey;

    bytes32 merkleRoot;
    address[] public whitelistBuyers;
    uint256[] public whitelistBuyersPrivateKeys;

    uint256 nftId;

    function setUp() public {
        owner = address(this);
        seller = makeAddr('seller');

        // test 100 whitelist buyers
        uint256 numWhitelist = 100;
        whitelistBuyers = new address[](numWhitelist);
        whitelistBuyersPrivateKeys = new uint256[](numWhitelist);

        for (uint256 i = 0; i < numWhitelist; i++) {
            whitelistBuyersPrivateKeys[i] = uint256(keccak256(abi.encodePacked('whitelistBuyer', i)));
            whitelistBuyers[i] = vm.addr(whitelistBuyersPrivateKeys[i]);
        }

        // build merkle tree
        bytes32[] memory leaves = new bytes32[](whitelistBuyers.length);
        for (uint256 i = 0; i < whitelistBuyers.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(whitelistBuyers[i]));
        }

        merkleRoot = computeMerkleRoot(leaves);

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
    function computeMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        if (leaves.length == 0) return 0;
        while (leaves.length > 1) {
            uint256 len = (leaves.length + 1) / 2;
            bytes32[] memory newLeaves = new bytes32[](len);
            for (uint256 i = 0; i < len; i++) {
                if (2 * i + 1 < leaves.length) {
                    newLeaves[i] = keccak256(
                        abi.encodePacked(
                            leaves[2 * i] < leaves[2 * i + 1] ? leaves[2 * i] : leaves[2 * i + 1],
                            leaves[2 * i] < leaves[2 * i + 1] ? leaves[2 * i + 1] : leaves[2 * i]
                        )
                    );
                } else {
                    newLeaves[i] = leaves[2 * i];
                }
            }
            leaves = newLeaves;
        }
        return leaves[0];
    }

    // get merkle proof
    function getMerkleProof(address user) public view returns (bytes32[] memory) {
        // find the index of the user in the whitelist
        uint256 index = type(uint256).max;
        for (uint256 i = 0; i < whitelistBuyers.length; i++) {
            if (whitelistBuyers[i] == user) {
                index = i;
                break;
            }
        }
        require(index != type(uint256).max, 'User not in whitelist');

        // build leaves
        bytes32[] memory leaves = new bytes32[](whitelistBuyers.length);
        for (uint256 i = 0; i < whitelistBuyers.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(whitelistBuyers[i]));
        }

        // compute the number of layers needed for the proof
        uint256 layers = 0;
        uint256 n = whitelistBuyers.length;
        while (n > 1) {
            n = (n + 1) / 2;
            layers++;
        }

        // create proof array
        bytes32[] memory proof = new bytes32[](layers);
        uint256 proofIndex = 0;
        n = whitelistBuyers.length;

        // current layer nodes
        bytes32[] memory currentLayer = leaves;
        uint256 currentIndex = index;

        // build proof from bottom to top
        while (currentLayer.length > 1) {
            bytes32[] memory nextLayer = new bytes32[]((currentLayer.length + 1) / 2);

            for (uint256 i = 0; i < currentLayer.length; i += 2) {
                uint256 j = i + 1;
                if (j == currentLayer.length) {
                    nextLayer[i / 2] = currentLayer[i];
                    continue;
                }

                bytes32 left = currentLayer[i];
                bytes32 right = currentLayer[j];

                // if the current index is one of the nodes in this pair, add the other one to the proof
                if (currentIndex == i || currentIndex == j) {
                    proof[proofIndex++] = currentIndex == i ? right : left;
                }

                nextLayer[i / 2] = keccak256(abi.encodePacked(left < right ? left : right, left < right ? right : left));
            }

            currentLayer = nextLayer;
            currentIndex = currentIndex / 2;
        }

        return proof;
    }
}
