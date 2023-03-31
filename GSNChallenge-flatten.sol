// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File contracts/GasToken.sol

pragma solidity ^0.8.0;

contract GasToken {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    address public relayer;

    event Transfer(address indexed from, address indexed to, uint value);

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address _relayer) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        _mint(msg.sender, _totalSupply);
        relayer = _relayer;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(to == relayer, "only relayer could be the receiver");
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        balanceOf[from] = fromBalance - amount;
    }
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}


// File contracts/RelayerChargeERC20Fee.sol


pragma solidity ^0.8.0;

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


// File contracts/RelayerHub.sol


pragma solidity ^0.8.0;

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


// File contracts/GSNChallenge.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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
