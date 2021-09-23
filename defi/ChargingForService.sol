// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./OwnableByToken.sol";

/**
 * @dev Fee taking module
 * AUTHOR: CAT6#2699
 */
contract ChargingForService is OwnableByToken /*Ownable*/ {
    event NewFeeToken(string, address, string, uint, string, uint);
    event NewFeeRate(uint);

    ERC20 private _feeToken;
    uint private _feeRate;
    uint private _feeFractionalUnits;
    
    /**
     * @dev Charges contract operator for the service fee.
    */
    modifier feeAllowance() {  
        if(msg.sender != owner()) { if(msg.sender != owner()){ 
            require(_feeToken.balanceOf(msg.sender) >= _feeRate * 10 ** _feeToken.decimals(), "ERROR: Insufficient feeToken Balance.");
            require(_feeToken.allowance(msg.sender, address(this)) >= _feeRate * 10 ** _feeToken.decimals(), "ERROR: Insufficient feeToken Allowance."); } } 
        _; }
    function _requireFeeAllowance() internal view {  
        if(msg.sender != owner()) { if(msg.sender != owner()){ 
            require(_feeToken.balanceOf(msg.sender) >= _feeRate * 10 ** _feeToken.decimals(), "ERROR: Insufficient feeToken Balance.");
            require(_feeToken.allowance(msg.sender, address(this)) >= _feeRate * 10 ** _feeToken.decimals(), "ERROR: Insufficient feeToken Allowance."); } } }

    /**
     * @dev Charges contract operator for the service fee.
    */
    function _chargeFee() internal { if(msg.sender != owner()) { _feeToken.transferFrom(msg.sender, owner(), _feeTokenValue()); } }
    function _feeTokenCorrectedDecimals() private view returns (uint) { return (_feeToken.decimals() / _feeFractionalUnits); }
    function _feeTokenValue() private view returns (uint) { return (_feeRate * 10 ** _feeTokenCorrectedDecimals()); }
    
    /**
     * @dev Owner can change fee currency. 
     */
    function oo_feeCurrencyChange(address tokenAddress, uint rate, uint fractionalUnits) 
    public 
    onlyOwner { 
        _feeToken = ERC20(tokenAddress);
        _feeRate = rate;
        _feeFractionalUnits = fractionalUnits;
            emit NewFeeToken("Address:", tokenAddress, " Rate:", rate, " fractionalUnits:", fractionalUnits); }

    /**
     * @dev Owner can change fee amount.
     */
    function oo_feeRateChange(uint rate) 
    public 
    onlyOwner { 
        _feeRate = rate;
            emit NewFeeRate(rate); }
} 