// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import { TokenBank } from '../src/Bank/TokenBankPermit.sol';
import '../src/BaseTokens/ERC20WithPermit.sol';
import 'permit2/src/interfaces/ISignatureTransfer.sol';
import 'permit2/src/interfaces/IPermit2.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import { DeployPermit2 } from 'permit2/test/utils/DeployPermit2.sol';

contract TokenBankTest is Test, DeployPermit2 {
    TokenBank public aTokenBank;
    SoToken public aToken;

    address public ownerAccount;
    uint256 internal ownerPrivateKey;

    IPermit2 public permit2;
    // Permit2 contract address
    // address constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function setUp() public {
        // deploy permit2
        permit2 = IPermit2(deployPermit2());
        console2.log('permit2');

        // Deploy token and bank
        aToken = new SoToken(address(this));
        aTokenBank = new TokenBank(address(aToken), address(permit2));

        // Setup ownerAccount
        ownerPrivateKey = 0xa11ce;
        ownerAccount = vm.addr(ownerPrivateKey);

        // Transfer tokens to ownerAccount
        aToken.transfer(ownerAccount, 500 * 10 ** 18);

        // User approves Permit2
        vm.startPrank(ownerAccount);
        aToken.approve(address(permit2), type(uint256).max);
        vm.stopPrank();
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

    function testDepositWithPermit2() public {
        uint256 depositAmount = 500 * 10 ** 18;

        // get the nonce
        uint256 wordPos = 0;
        uint256 bitmap = permit2.nonceBitmap(ownerAccount, wordPos);
        uint256 nonce = _findNextNonce(bitmap, wordPos);
        console2.log('nonce:', nonce);

        uint256 deadline = block.timestamp + 1 hours;

        // Create permit message
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({ token: address(aToken), amount: depositAmount }),
            nonce: nonce,
            deadline: deadline
        });

        console2.log('Initial user balance: %d', aToken.balanceOf(ownerAccount));
        console2.log('Initial bank balance: %d', aToken.balanceOf(address(aTokenBank)));
        console2.log('Permit2 allowance: %d', aToken.allowance(ownerAccount, address(permit2)));

        // get the digest
        bytes32 digest = _getPermitTransferFromDigest(permit, address(aTokenBank), address(permit2));
        console2.log('digest: %s', Strings.toHexString(uint256(digest)));

        // sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        console2.log('v: %s', Strings.toHexString(uint256(v)));
        console2.log('r: %s', Strings.toHexString(uint256(r)));
        console2.log('s: %s', Strings.toHexString(uint256(s)));

        // encode the signature
        bytes memory signature = abi.encodePacked(r, s, v);
        console2.log('signature:');
        console2.logBytes(signature);

        // Execute deposit with permit2
        vm.prank(ownerAccount);
        aTokenBank.depositWithPermit2(aToken, depositAmount, nonce, deadline, signature);

        console2.log('bank balance: %d', aTokenBank.balances(ownerAccount));
        console2.log('bank token balance: %d', aToken.balanceOf(address(aTokenBank)));

        // Verify deposit
        assertEq(aTokenBank.balances(ownerAccount), depositAmount, 'Bank balance should match deposit amount');
        assertEq(aToken.balanceOf(address(aTokenBank)), depositAmount, 'Bank token balance should increase by deposit amount');
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
