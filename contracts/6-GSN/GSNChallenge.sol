// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./GasToken.sol";
import "./RelayerHub.sol";

contract GSNChallenge {
    address public owner;

    mapping(address => address) public relayerHubMap;
    mapping(address => bool) public challenged;

    RelayerHub public relayerHub;
    GasToken public gasToken;
    address public relayer;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier onlyChallenger() {
        require(relayerHubMap[msg.sender] != address(0), "only challenger");
        require(!challenged[msg.sender], "already challenged 1");
        _;
    }

    modifier onlyNotRegister() {
        require(relayerHubMap[msg.sender] == address(0), "already register");
        _;
    }

    receive() external payable {}

    constructor() {
        owner = msg.sender;
        relayerHub = new RelayerHub();
        relayer = address(relayerHub.relayer());

        gasToken = new GasToken('GasToken', 'GasToken', 1_000_000 ether, relayer);
        gasToken.transfer(relayer, 1_5000 ether);

        relayerHub.setGasToken(address(gasToken), 1000);
    }

    function close() external onlyOwner {
        payable(msg.sender).call{  value: address(this).balance }("");
    }

    function register() external onlyNotRegister returns (address) {
        relayerHubMap[msg.sender] = address(relayerHub);
        gasToken.transfer(msg.sender, 1 ether);
        return relayerHubMap[msg.sender];
    }

    function withdraw() external onlyChallenger {
        uint256 profitAtLeast = 10_000 ether;
        require(gasToken.balanceOf(msg.sender) >= profitAtLeast, "1 not solved");

        // reward
        (bool success, ) = payable(msg.sender).call{ value: 0.02 ether }("");
        require(success, 'eth not enough');

        challenged[msg.sender] = true;
    }
}
