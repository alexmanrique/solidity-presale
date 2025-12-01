// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IAggregator} from "./interfaces/IAggregator.sol";

contract Presale is Ownable {
    using SafeERC20 for IERC20;
    address public usdtAddress;
    address public usdcAddress;
    address public fundsReceiverAddress;
    uint256 public totalAmountSold;
    uint256 public maxSellingAmount;
    uint256[][3] public phases;

    uint256 public startingTime;
    uint256 public endingTime;
    uint256 public currentPhase;
    address public dataFeedAddress;
    address public saleTokenAddress;

    mapping(address => bool) public isBlackListed;
    mapping(address => uint256) public userTokenBalance;

    event TokenBuy(address user, uint256 amount);
    event TokensClaimed(address user, uint256 amount);

    constructor(
        address usdtAddress_,
        address usdcAddress_,
        address fundsReceiverAddress_,
        uint256 maxSellingAmount_,
        uint256[][3] memory phases_,
        uint256 startingTime_,
        uint256 endingTime_,
        address dataFeedAddress_,
        address saleTokenAddress_
    ) Ownable(msg.sender) {
        usdtAddress = usdtAddress_;
        usdcAddress = usdcAddress_;
        fundsReceiverAddress = fundsReceiverAddress_;
        maxSellingAmount = maxSellingAmount_;
        phases = phases_;
        startingTime = startingTime_;
        endingTime = endingTime_;
        dataFeedAddress = dataFeedAddress_;
        saleTokenAddress = saleTokenAddress_;

        require(startingTime < endingTime, "Starting time must be before ending time");

        IERC20(saleTokenAddress).safeTransferFrom(msg.sender, address(this), maxSellingAmount);
    }

    function blackList(address user) external onlyOwner {
        isBlackListed[user] = true;
    }

    function removeBlacklist(address user_) external onlyOwner {
        isBlackListed[user_] = false;
    }

    function buyWithStable(address tokenUsedToBuy_, uint256 amount_) external {
        require(!isBlackListed[msg.sender], "You are blacklisted");
        require(block.timestamp >= startingTime && block.timestamp <= endingTime, "Presale is not active");
        require(tokenUsedToBuy_ == usdtAddress || tokenUsedToBuy_ == usdcAddress, "Invalid token");

        uint256 tokenAmountToReceive;

        if (ERC20(tokenUsedToBuy_).decimals() == 18) {
            tokenAmountToReceive = amount_ * 1e6 / phases[currentPhase][1];
        } else {
            tokenAmountToReceive =
                amount_ * 10 ** (18 - ERC20(tokenUsedToBuy_).decimals()) * 1e6 / phases[currentPhase][1];
        }
        checkCurrentPhase(tokenAmountToReceive);
        totalAmountSold += tokenAmountToReceive;
        require(totalAmountSold <= maxSellingAmount, "Sold out");

        userTokenBalance[msg.sender] += tokenAmountToReceive;

        IERC20(tokenUsedToBuy_).safeTransferFrom(msg.sender, fundsReceiverAddress, amount_);

        emit TokenBuy(msg.sender, tokenAmountToReceive);
    }

    function buyWithEth() external payable {
        require(!isBlackListed[msg.sender], "You are blacklisted");
        require(block.timestamp >= startingTime && block.timestamp <= endingTime, "Presale is not active");

        uint256 tokenAmountToReceive;

        uint256 usdValue = msg.value * getEtherPrice() / 1e18;

        tokenAmountToReceive = usdValue * 1e6 / phases[currentPhase][1];

        checkCurrentPhase(tokenAmountToReceive);

        totalAmountSold += tokenAmountToReceive;
        require(totalAmountSold <= maxSellingAmount, "Sold out");

        userTokenBalance[msg.sender] += tokenAmountToReceive;

        (bool success,) = fundsReceiverAddress.call{value: msg.value}("");
        require(success, "ETH transfer failed");

        emit TokenBuy(msg.sender, tokenAmountToReceive);
    }

    function getEtherPrice() public view returns (uint256) {
        (, int256 price,,,) = IAggregator(dataFeedAddress).latestRoundData();
        price = price * (10 ** 10);
        return uint256(price);
    }

    function claimTokens() external {
        require(userTokenBalance[msg.sender] > 0, "No tokens to claim");
        require(block.timestamp > endingTime, "Presale is not over");

        delete userTokenBalance[msg.sender];
        IERC20(saleTokenAddress).safeTransfer(msg.sender, userTokenBalance[msg.sender]);

        emit TokensClaimed(msg.sender, userTokenBalance[msg.sender]);
    }

    function emergencyWithdraw(address tokenAddress_, uint256 amount_) external onlyOwner {
        IERC20(tokenAddress_).safeTransfer(msg.sender, amount_);
    }

    function emergencyWithdrawEth() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    function checkCurrentPhase(uint256 amount_) private returns (uint256 phase) {
        if (
            (totalAmountSold + amount_ >= phases[currentPhase][0])
                || ((block.timestamp >= phases[currentPhase][2]) && currentPhase < 3)
        ) {
            currentPhase++;
            phase = currentPhase;
        }
        phase = currentPhase;
    }
}
