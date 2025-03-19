// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from 'forge-std/Test.sol';
import { TokenBank } from '../src/Bank/TokenBankPermit.sol';
import '../src/BaseTokens/ERC20WithPermit.sol';

contract TokenBankTest is Test {
    TokenBank public aTokenBank;
    SoToken public aToken;

    address public ownerAccount;
    uint256 internal ownerPrivateKey;

    function setUp() public {
        ownerPrivateKey = 0xa11ce;
        ownerAccount = vm.addr(ownerPrivateKey);

        aToken = new SoToken(address(this));
        aTokenBank = new TokenBank(address(aToken), address(0));
        aToken.transfer(ownerAccount, 500 * 10 ** 18);
    }

    function testPermitDeposit() public {
        // Prepare test data
        uint256 depositAmount = 100 * 10 ** 18;
        uint256 deadline = block.timestamp + 1 days;
        uint256 nonce = aToken.nonces(ownerAccount);

        bytes32 permitDataHashStruct = keccak256(
            abi.encode(
                keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'),
                ownerAccount,
                address(aTokenBank),
                depositAmount,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', aToken.DOMAIN_SEPARATOR(), permitDataHashStruct));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Start to test
        vm.prank(ownerAccount);
        aTokenBank.permitDeposit(depositAmount, deadline, v, r, s);

        // Check result
        assertEq(aToken.balanceOf(address(aTokenBank)), depositAmount, 'Bank should have recieved 100 tokens');

        assertEq(
            aToken.balanceOf(ownerAccount),
            400 * 10 ** 18, //500-100
            'OwnerAccount should have 100 tokens in Bank'
        );
    }

    // find the next available nonce
    function _findNextNonce(uint256 bitmap, uint256 wordPos) internal pure returns (uint256) {
        // find the first unused bit in the current bitmap
        uint256 bit;
        for (bit = 0; bit < 256; bit++) {
            if ((bitmap & (1 << bit)) == 0) {
                break;
            }
        }

        // calculate the full nonce
        // nonce = (wordPos << 8) | bit
        return (wordPos << 8) | bit;
    }

    function _getPermitTransferFromDigest(
        ISignatureTransfer.PermitTransferFrom memory permit,
        address spender,
        address permit2Address
    ) internal view returns (bytes32) {
        // get the domain separator
        bytes32 DOMAIN_SEPARATOR = IPermit2(permit2Address).DOMAIN_SEPARATOR();
        console2.log('DOMAIN_SEPARATOR: %s', vm.toString(DOMAIN_SEPARATOR));

        // get the type hash
        bytes32 typeHash = keccak256(
            'PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)'
        );

        // get the token permissions hash
        bytes32 tokenPermissionsHash = keccak256(
            abi.encode(keccak256('TokenPermissions(address token,uint256 amount)'), permit.permitted.token, permit.permitted.amount)
        );

        // get the struct hash
        bytes32 structHash = keccak256(abi.encode(typeHash, tokenPermissionsHash, spender, permit.nonce, permit.deadline));

        // get the final digest
        return keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash));
    }
}
