// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTFi {
    mapping(address => uint256) public stakingNFT;
    mapping(address => uint256) public balanceOf;
    address public nft;

    constructor(address _nft) {
        nft = _nft;
    }

    function stakeAndLending() external {
        // stake
        IERC721(nft).transferFrom(msg.sender, address(this), 1);
        stakingNFT[msg.sender] = 1;

        // lending
        balanceOf[msg.sender] += 10;
    }

    function withdrawNFT() external payable {
        uint256 _tokenId = stakingNFT[msg.sender];
        require(_tokenId > 0, "not staking");
        IERC721(nft).safeTransferFrom(address(this), msg.sender, _tokenId, "");
        balanceOf[msg.sender] -= 10;
        stakingNFT[msg.sender] = 0;
    }
}
