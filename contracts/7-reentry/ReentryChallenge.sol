// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./NFTFi.sol";

contract myNFT is ERC721 {
    constructor(string memory name, string memory symbol, address receiver) ERC721(name, symbol) {
        _mint(receiver, 1);
    }
}

abstract contract Ownable {
    address private _owner;
    constructor() {
        _owner = msg.sender;
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }
}

contract ReentryChallenge is Ownable {
    mapping(address => address) public nftfiMap;
    mapping(address => bool) public challenged;

    modifier onlyChallenger() {
        require(nftfiMap[msg.sender] != address(0), "only challenger");
        require(!challenged[msg.sender], "already challenged 1");
        _;
    }

    modifier onlyNotRegister() {
        require(nftfiMap[msg.sender] == address(0), "already register");
        _;
    }

    receive() external payable {}

    function close() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function register() external onlyNotRegister returns (address) {
        myNFT _nft = new myNFT("ReentryChallenge", "ReentryChallenge", msg.sender);
        NFTFi nftfi = new NFTFi(address(_nft));
        nftfiMap[msg.sender] = address(nftfi);

        return address(nftfi);
    }

    function withdraw() external onlyChallenger {
        address _nftfi = nftfiMap[msg.sender];
        require(_nftfi != address(0), "not register");

        NFTFi nftfi = NFTFi(_nftfi);
        require(nftfi.balanceOf(msg.sender) >= 30, "not solved");

        (bool success, ) = msg.sender.call{value: 0.1 ether}("");
        require(success, "Failed to send bnb");
        challenged[msg.sender] = true;
    }
}
