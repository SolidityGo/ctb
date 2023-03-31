// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;
import "../v2-periphery/interfaces/IUniswapV2Factory.sol";
import "./ABC.sol";

contract XYZ is IERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    address public uniswapV2Pair;
    IUniswapV2Factory public PANCAKE_FACTORY = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    address public owner;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address usdx) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        _mint(msg.sender, _totalSupply);
        owner = msg.sender;
        uniswapV2Pair = PANCAKE_FACTORY.createPair(address(this), usdx);
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
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

        uint256 fee = 0;

        // take sell fee to the token contract
        if (from != owner && to == uniswapV2Pair) {
            fee = amount * 2 / 10;
        }

        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= amount + fee, "ERC20: transfer amount exceeds balance");
        unchecked {
            balanceOf[from] = fromBalance - amount - fee;
        }
        balanceOf[to] += amount;
        balanceOf[address(this)] += fee;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

}

