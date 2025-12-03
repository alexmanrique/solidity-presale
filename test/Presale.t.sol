// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console2} from "../lib/forge-std/src/console2.sol";
import {Presale} from "../src/Presale.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract PresaleTest is Test {
    Presale presale;
    ERC20Mock saleToken;
    address saleTokenAddress_;
    address usdtAddress_ = vm.addr(2);
    address usdcAddress_ = vm.addr(3);
    address fundsReceiverAddress_ = vm.addr(4);
    address dataFeedAddress_ = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    uint256 maxSellingAmount_ = 30000000 * 1e18;
    uint256 startingTime_ = block.timestamp;
    uint256 endingTime_ = block.timestamp + 5000;
    uint256[][3] phases_;

    // Función para recibir ETH en el contrato de test
    receive() external payable {}

    function setUp() public {
        phases_[0] = [10000000 * 1e18, 5000, block.timestamp + 1000];
        phases_[1] = [10000000 * 1e18, 500, block.timestamp + 1000];
        phases_[2] = [10000000 * 1e18, 50, block.timestamp + 1000];

        // Crear mock de token ERC20
        saleToken = new ERC20Mock();
        saleTokenAddress_ = address(saleToken);

        // Mintear tokens al contrato de test
        saleToken.mint(address(this), maxSellingAmount_);

        // Calcular la dirección del contrato Presale antes de deployarlo
        address presaleAddress = vm.computeCreateAddress(address(this), vm.getNonce(address(this)));

        // Hacer approve desde el contrato de test hacia el contrato Presale
        saleToken.approve(presaleAddress, maxSellingAmount_);

        presale = new Presale(
            saleTokenAddress_,
            usdtAddress_,
            usdcAddress_,
            fundsReceiverAddress_,
            dataFeedAddress_,
            maxSellingAmount_,
            phases_,
            startingTime_,
            endingTime_
        );
    }

    function testAddToBlacklist() public {
        presale.blackList(vm.addr(2));
        assertEq(presale.isBlackListed(vm.addr(2)), true);
    }

    function testRemoveFromBlacklist() public {
        presale.removeBlacklist(vm.addr(2));
        assertEq(presale.isBlackListed(vm.addr(2)), false);
    }

    function testEmergencyWithdrawSuccessfullIfOwner() public {
        vm.prank(address(presale.owner()));
        uint256 amount_ = 10000000 * 1e18;
        IERC20(saleTokenAddress_).approve(address(presale), amount_);
        presale.emergencyWithdraw(saleTokenAddress_, amount_);
        assertEq(saleToken.balanceOf(address(presale)), maxSellingAmount_ - amount_);
        assertEq(saleToken.balanceOf(address(presale.owner())), amount_);
        vm.stopPrank();
    }

    function testEmergencyWithdrawFailedIfNotOwner() public {
        vm.prank(vm.addr(2));
        uint256 amount_ = 10000000 * 1e18;
        vm.expectRevert();
        presale.emergencyWithdraw(saleTokenAddress_, amount_);
        vm.stopPrank();
    }

    function testEmergencyWithdrawEthSuccessfullIfOwner() public {
        address owner = address(presale.owner());
        uint256 initialBalance = owner.balance;
        uint256 amount_ = 10000000 * 1e18;
        vm.deal(address(presale), amount_);
        vm.prank(owner);
        presale.emergencyWithdrawEth();
        assertEq(address(presale).balance, 0);
        assertEq(owner.balance, initialBalance + amount_);
    }

   function testEmergencyWithdrawEthFailedIfNotOwner() public {
        uint256 amount_ = 10000000 * 1e18;
        vm.deal(address(presale), amount_);
        vm.prank(vm.addr(2));
        vm.expectRevert();
        presale.emergencyWithdrawEth();
        vm.stopPrank();
    }

    function testClaimTokensFailureIfNotTokensToClaim() public {
        vm.prank(vm.addr(2));
        vm.expectRevert();
        presale.claimTokens();
        vm.stopPrank();
    }

    function testBuyWithStableFailureIfBlacklisted() public {
        presale.blackList(vm.addr(2));
        vm.prank(vm.addr(2));
        vm.expectRevert("You are blacklisted");
        presale.buyWithStable(usdtAddress_, 10000000 * 1e18);
        vm.stopPrank();
    }

    function testBuyWithStableFailureIfNotActive() public {
        vm.warp(endingTime_ + 1000);
        vm.prank(vm.addr(2));
        vm.expectRevert("Presale is not active");
        presale.buyWithStable(usdtAddress_, 10000000 * 1e18);
        vm.stopPrank();
    }

    function testBuyWithStableFailureIfInvalidToken() public {
        vm.prank(vm.addr(2));
        vm.expectRevert("Invalid token");
        presale.buyWithStable(address(0), 10000000 * 1e18);
        vm.stopPrank();
    }

    /*function testBuyWithStable() public {
        vm.prank(vm.addr(2));
        vm.warp(phases_[0][2] - 500);
        uint256 amount_ = 100000000 * 1e18;
        presale.buyWithStable(usdtAddress_, amount_);
        assertEq(fundsReceiverAddress_.balance, amount_);
        assertEq(saleToken.balanceOf(address(presale)), maxSellingAmount_ - amount_);
        assertEq(saleToken.balanceOf(address(vm.addr(2))), amount_);
        vm.stopPrank();
    }*/

     /*
     function testClaimTokensFailureIfStillInPreSaleTime() public {
        vm.prank(vm.addr(2));
        vm.warp(endingTime_ - 1000);
        vm.expectRevert();
        presale.claimTokens();
        vm.stopPrank();
    }*/

}
