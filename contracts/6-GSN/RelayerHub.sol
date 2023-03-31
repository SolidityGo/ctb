// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './RelayerChargeERC20Fee.sol';

contract RelayerHub {
    address public owner;
    RelayerChargeERC20Fee public relayer;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        relayer = new RelayerChargeERC20Fee();
    }

    function setGasToken(address gasToken, uint256 exchangeRate) external onlyOwner {
        relayer.setGasToken(gasToken, exchangeRate);
    }

    // 1. sender request relayer server to relay a tx (address target, bytes memory data, uint256 gasLimit, uint256 expectGasPrice) offline
    // 2. relayer server call this function `sendRelayTx ` to relay call after verified the senderSignature
    // 3. relayer server charge fee by ERC20 - GasToken
    function sendRelayTx(address sender, address target, bytes memory data, uint256 gasLimit, uint256 expectGasPrice, bytes memory senderSignature) external {
        // verify senderSignature
        bytes32 _msgHash = toEthSignedMessageHash(keccak256(abi.encode(sender, target, data, gasLimit, expectGasPrice)));
        require(recoverSigner(_msgHash, senderSignature) == sender, "sender sig not verified");

        // check params
        require(tx.gasprice >= expectGasPrice, "tx.gasprice not enough");

        // charge max fee by ERC20 before relayCall
        uint256 chargedErc20Fee = relayer.preRelayedCall(msg.sender, gasLimit, expectGasPrice);

        uint256 beforeGas = gasleft();
        (bool success, bytes memory returnData) = relayer.relayCall(target, data, gasLimit);
        uint256 gasUsed = beforeGas - gasleft();

        // calc actual fee, return the remaining erc20 fee
        relayer.postRelayedCall(sender, chargedErc20Fee, gasUsed, expectGasPrice);
    }

    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
        /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}
