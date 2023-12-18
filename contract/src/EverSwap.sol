//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC4626} from "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EverSwap is ERC4626{

    error EVERSWAPInsufficientFundsToWithdraw(address owner, uint256 assets, uint256 totalAssets);

    IERC20 private usdc_token; 

    struct Borrower {
        uint256 collateral;
        uint256 debt;
        Position position;
    }

    uint256 private LPValue;
    uint256 private totalOpenInterest;
    int256 private currentPnL;
    uint256 private totalCloseInterest;
    uint256 private totalDeposits;
    uint256 private totalShares;

    mapping(address => uint256) private addressToShares;
    mapping(address => uint256) private addressToDeposits;
    mapping(address => Borrower) private addressToBorrower;

    enum Position {LONG, SHORT}

    constructor() ERC4626(usdc_token) ERC20("EverSwap", "ESW"){
        usdc_token = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    function totalAssets() public override view returns(uint256){
        require(int256(usdc_token.balanceOf(address(this))) >= currentPnL, "EverSwap: Insufficient funds to cover PnL");
        int256 currentLPValue = int256(usdc_token.balanceOf(address(this))) - currentPnL;
        return uint256(currentLPValue);
    }

    function deposit(uint256 assets, address receiver) public override returns(uint256){
        require(receiver == address(this), "EverSwap: Receiver must be this contract");
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        totalDeposits += assets;
        addressToShares[receiver] += shares;
        addressToDeposits[receiver] += assets;

        return shares;
    }
 
    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        if(assets > totalAssets()){
            revert EVERSWAPInsufficientFundsToWithdraw(owner, assets, totalAssets());
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        addressToShares[owner] -= shares;
        addressToDeposits[owner] -= assets;

        return shares;
    }

    function calculateLeverage(uint256 collateral, uint256 debt) public virtual pure returns(uint256){
        return debt/collateral;
    }


    function borrow(uint256 assets, uint256 collateral, Position _position) public virtual returns(bool){
        require(assets <= totalAssets(), "EverSwap: Insufficient funds to borrow");

        if(_position == Position.LONG){
            totalOpenInterest += assets;
        } else {
            totalCloseInterest += assets;
        }

        Borrower memory borrower = Borrower(collateral, assets, _position);

        addressToBorrower[_msgSender()] = borrower;

        return true;

    }

    function liquidate(address borrower) public virtual returns(bool){
        Borrower memory _borrower = addressToBorrower[borrower];
        uint256 collateral = _borrower.collateral;
        uint256 debt = _borrower.debt;

        uint256 leverage = calculateLeverage(collateral, debt);

        if(leverage > 2){
            if(_borrower.position == Position.LONG){
                totalOpenInterest -= debt;
            } else {
                totalCloseInterest -= debt;
            }

            delete addressToBorrower[borrower];
            totalDeposits += collateral;
        }else{
            revert("EverSwap: Borrower is not liquidatable");
        }

        return true;

    }

    function closeBorrowerPosition(address _borrower) public virtual returns(bool){
        Borrower memory borrower = addressToBorrower[_borrower];
        uint256 collateral = borrower.collateral;
        uint256 debt = borrower.debt;
    
        if(borrower.position == Position.LONG){
             
        }else {
            
        }
    }


}

