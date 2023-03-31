// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './GasToken.sol';


contract RelayerChargeERC20Fee {
    address public relayerHub;
    GasToken public gasToken;
    uint256 public gasTokenExchangeRate;

    modifier onlyRelayerHub() {
        require(msg.sender == relayerHub, "only RelayerHub");
        _;
    }

    constructor() {
        relayerHub = msg.sender;
    }

    function setGasToken(address _gasToken, uint256 _gasTokenExchangeRate) external onlyRelayerHub {
        gasToken = GasToken(_gasToken);
        gasTokenExchangeRate = _gasTokenExchangeRate;
    }

    function preRelayedCall(address sender, uint256 gasLimit, uint256 expectGasPrice) external onlyRelayerHub returns (uint256 chargedMaxFee){
        uint256 maxPossibleCharge = expectGasPrice * gasLimit * gasTokenExchangeRate;
        // The maximum token charge is pre-charged from the user
        gasToken.transferFrom(sender, address(this), maxPossibleCharge);
        return maxPossibleCharge;
    }

    function relayCall(address target, bytes memory data, uint256 gasLimit) external onlyRelayerHub returns (bool success, bytes memory returnData) {
        (success, returnData) = target.delegatecall{ gas: gasLimit }(data);
        return (success, returnData);
    }

    function postRelayedCall(address sender, uint256 chargedErc20Fee, uint256 gasUsed, uint256 expectGasPrice) external onlyRelayerHub {
        uint256 actualCharge = gasUsed * expectGasPrice * gasTokenExchangeRate;

        // After the relayed call has been executed and the actual charge estimated, the excess pre-charge is returned
        gasToken.transfer(sender, chargedErc20Fee - actualCharge);
    }
}
