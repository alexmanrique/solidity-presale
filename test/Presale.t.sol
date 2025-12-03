// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console2} from "../lib/forge-std/src/console2.sol";
import {Presale} from "../src/Presale.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Mock para USDT con 6 decimales
contract USDTMock is ERC20 {
    constructor() ERC20("Tether USD", "USDT") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

// Mock para USDC con 6 decimales
contract USDCMock is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract WETHMock is ERC20 {
    constructor() ERC20("Wrapped Ether", "WETH") {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract PresaleTest is Test {
    Presale presale;
    ERC20Mock saleToken;
    USDTMock usdtToken;
    USDCMock usdcToken;
    WETHMock wethToken;
    
    address saleTokenAddress_;
    address usdtAddress_;
    address usdcAddress_;
    address wethAddress_;
    
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

        // Crear mocks de USDT y USDC
        usdtToken = new USDTMock();
        usdtAddress_ = address(usdtToken);
        
        usdcToken = new USDCMock();
        usdcAddress_ = address(usdcToken);

        wethToken = new WETHMock();
        wethAddress_ = address(wethToken);

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
            wethAddress_,
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

    function testBuyWithUsdtSuccessfull() public {
        vm.warp(phases_[0][2] - 500);
        
        address buyer = vm.addr(2);
        uint256 amount_ = 10 * 1e6; // USDT tiene 6 decimales
        
        // Mintear USDT al comprador
        usdtToken.mint(buyer, amount_);
        
        // Calcular cuántos tokens debería recibir
        // Para USDT con 6 decimales: amount_ * 10^(18-6) * 1e6 / phases[0][1]
        // = amount_ * 1e12 * 1e6 / 5000 = amount_ * 1e18 / 5000
        uint256 expectedTokens = amount_ * 1e12 * 1e6 / phases_[0][1];
        
        // Aprobar el contrato presale para transferir USDT y realizar la compra
        vm.startPrank(buyer);
        usdtToken.approve(address(presale), amount_);
        presale.buyWithStable(usdtAddress_, amount_);
        vm.stopPrank();
        
        // Verificar que el fundsReceiverAddress recibió los USDT
        assertEq(usdtToken.balanceOf(fundsReceiverAddress_), amount_);
        
        // Verificar que el balance del usuario se actualizó correctamente
        assertEq(presale.userTokenBalance(buyer), expectedTokens);
        
        // Verificar que el presale aún tiene los tokens (no se transfieren hasta claim)
        assertEq(saleToken.balanceOf(address(presale)), maxSellingAmount_);
    }


    function testBuyWithUsdcSuccessfull() public {
        vm.warp(phases_[0][2] - 500);
        
        address buyer = vm.addr(2);
        uint256 amount_ = 10 * 1e6; // USDC tiene 6 decimales
        
        // Mintear USDC al comprador
        usdcToken.mint(buyer, amount_);
        
        uint256 expectedTokens = amount_ * 1e12 * 1e6 / phases_[0][1];

        vm.startPrank(buyer);
        usdcToken.approve(address(presale), amount_);
        presale.buyWithStable(usdcAddress_, amount_);
        vm.stopPrank();
        
        // Verificar que el fundsReceiverAddress recibió los USDC
        assertEq(usdcToken.balanceOf(fundsReceiverAddress_), amount_);
        
        // Verificar que el balance del usuario se actualizó correctamente
        assertEq(presale.userTokenBalance(buyer), expectedTokens);
        
        // Verificar que el presale aún tiene los tokens (no se transfieren hasta claim)
        assertEq(saleToken.balanceOf(address(presale)), maxSellingAmount_);
    }

    function testBuyWithWethSuccessfull() public {
        vm.warp(phases_[0][2] - 500);
        
        address buyer = vm.addr(2);
        uint256 amount_ = 10 * 1e18; // WETH tiene 18 decimales
        
        // Mintear WETH al comprador
        wethToken.mint(buyer, amount_);

        uint256 expectedTokens = amount_ * 1e6 / phases_[0][1];

        vm.startPrank(buyer);
        wethToken.approve(address(presale), amount_);
        presale.buyWithStable(wethAddress_, amount_);
        vm.stopPrank();
        
        // Verificar que el fundsReceiverAddress recibió los WETH
        assertEq(wethToken.balanceOf(fundsReceiverAddress_), amount_);
        
        // Verificar que el balance del usuario se actualizó correctamente
        assertEq(presale.userTokenBalance(buyer), expectedTokens);
        
        // Verificar que el presale aún tiene los tokens (no se transfieren hasta claim)
        assertEq(saleToken.balanceOf(address(presale)), maxSellingAmount_);
    }

     /*
     function testClaimTokensFailureIfStillInPreSaleTime() public {
        vm.prank(vm.addr(2));
        vm.warp(endingTime_ - 1000);
        vm.expectRevert();
        presale.claimTokens();
        vm.stopPrank();
    }*/

}
