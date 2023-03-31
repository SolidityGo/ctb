// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ABC.sol";
import "./XYZ.sol";

interface IUniswapRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 InitAmountADesired,
        uint256 InitAmountBDesired,
        uint256 InitAmountAMin,
        uint256 InitAmountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 InitAmountA,
        uint256 InitAmountB,
        uint256 liquidity
    );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 InitAmountIn,
        uint256 InitAmountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract TokenChallenge is Ownable {
    uint256 public constant MAX_UINT256 = type(uint256).max;
    uint256 public constant INIT_AMOUNT = 10_000_000 ether;
    
    mapping(address => address) public usdAMap;
    mapping(address => address) public abcMap;

    mapping(address => address) public usdXMap;
    mapping(address => address) public usdYMap;
    mapping(address => address) public usdZMap;
    mapping(address => address) public xyzMap;

    mapping(address => bool) public challenged1;
    mapping(address => bool) public challenged2;

    IUniswapRouter private PANCAKE_ROUTER = IUniswapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    
    modifier onlyChallenger1() {
        require(usdAMap[msg.sender] != address(0), "only challenger");
        require(!challenged1[msg.sender], "already challenged 1");
        _;
    }

    modifier onlyChallenger2() {
        require(usdXMap[msg.sender] != address(0), "only challenger");
        require(!challenged2[msg.sender], "already challenged 2");
        _;
    }

    modifier onlyNotRegister() {
        require(usdAMap[msg.sender] == address(0), "already register");
        _;
    }

    receive() external payable {}

    function close() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _register1() internal {
        USD usda = new USD("USDA", "USDA", INIT_AMOUNT);
        ABC abc = new ABC("ABC", "ABC", INIT_AMOUNT);
        usdAMap[msg.sender] = address(usda);
        abcMap[msg.sender] = address(abc);

        usda.transfer(msg.sender, 1 ether);
        abc.transfer(msg.sender, 1 ether);

        usda.approve(address(PANCAKE_ROUTER), MAX_UINT256);
        abc.approve(address(PANCAKE_ROUTER), MAX_UINT256);
        PANCAKE_ROUTER.addLiquidity(
            address(usda),
            address(abc),
            usda.balanceOf(address(this)),
            abc.balanceOf(address(this)),
            1,
            1,
            address(this),
            block.timestamp
        );
    }
    
    function _register2() internal {
        USD usdx = new USD("USDX", "USDX", INIT_AMOUNT * 2);
        USD usdy = new USD("USDY", "USDY", INIT_AMOUNT * 2);
        USD usdz = new USD("USDZ", "USDZ", INIT_AMOUNT * 2);
        XYZ xyz = new XYZ("XYZ", "XYZ", INIT_AMOUNT * 2, address(usdx));
        usdXMap[msg.sender] = address(usdx);
        usdYMap[msg.sender] = address(usdy);
        usdZMap[msg.sender] = address(usdz);
        xyzMap[msg.sender] = address(xyz);
        
        usdx.approve(address(PANCAKE_ROUTER), MAX_UINT256);
        usdy.approve(address(PANCAKE_ROUTER), MAX_UINT256);
        usdz.approve(address(PANCAKE_ROUTER), MAX_UINT256);
        xyz.approve(address(PANCAKE_ROUTER), MAX_UINT256);

        // add lp-usdx-xyz
        PANCAKE_ROUTER.addLiquidity(address(usdx), address(xyz), INIT_AMOUNT, INIT_AMOUNT, 1, 1, address(this), block.timestamp);

        // add lp-usdy-xyz
        PANCAKE_ROUTER.addLiquidity(address(usdy), address(xyz), INIT_AMOUNT, INIT_AMOUNT, 1, 1, address(this), block.timestamp);

        // add lp-usdy-usdz
        PANCAKE_ROUTER.addLiquidity(address(usdy), address(usdz), INIT_AMOUNT, INIT_AMOUNT, 1, 1, address(this), block.timestamp);
    }
    
    function register() external onlyNotRegister {
        _register1();
        _register2();
    }

    function withdraw1() external onlyChallenger1 {
        address usda = usdAMap[msg.sender];
        uint256 profitAtLeast = 700_0000 ether;
        require(USD(usda).balanceOf(msg.sender) > 1 ether + profitAtLeast, "1 not solved");

        // reward
        payable(msg.sender).transfer(0.04 ether);
        challenged1[msg.sender] = true;
    }

    function withdraw2() external onlyChallenger2 {
        address usdy = usdYMap[msg.sender];
        uint256 profitAtLeast = 1_000_000 ether; 
        require(USD(usdy).balanceOf(msg.sender) > profitAtLeast, "2 not solved");

        // reward
        payable(msg.sender).transfer(0.08 ether);
        challenged2[msg.sender] = true;
    }
}
