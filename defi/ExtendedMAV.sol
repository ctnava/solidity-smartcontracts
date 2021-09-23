// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./MultiAssetVault.sol";

// Contract by CAT6#2699
interface Extended_IMAV {
    function viewDeposit(uint depositId) external view returns(string memory, string memory, uint, uint, address, string memory); 
    function _viewDeposit(uint depositId) external view returns(uint, address, uint, uint, address, uint);   
    function typeOfDeposit(uint depositId) external view returns(string memory);
    function statusOf(uint depositId) external view returns(string memory); }

abstract contract Extended_MultiAssetVault is MultiAssetVault, Extended_IMAV {
    function viewDeposit(uint depositId) public view override returns(string memory, string memory, uint, uint, address, string memory) { 
        AssetType depType = depositType_(depositId);
        address depositor = depositorOf(depositId);
        string memory typeName = typeOfDeposit(depositId);
        string memory message = statusOf(depositId);
        string memory tokenName;
        if(depType == AssetType.ERC20) { 
            tokenName = depositedToken_(depositId).name();
            return (typeName, tokenName, _depositPreDec(depositId), _depositPostDec(depositId), depositorOf(depositId), message); } 
        if(depType == AssetType.ERC721) { 
            tokenName = depositedNFT_(depositId).name();
            return (typeName, tokenName, _depositValue(depositId), 0, depositor, message); } 
        else {
            return("ERROR: Deposit Nonexistent", "", 0, 0, address(0), ""); } } 
            
    function _viewDeposit(uint depositId) 
    public view override 
    returns(uint, address, uint, uint, address, uint) { 
        return(_depositType(depositId), depositedAssetAddress(depositId), depositedInt_(depositId), depositedUnits_(depositId), depositorOf(depositId), _statusOf(depositId)); } 
    
    function typeOfDeposit(uint depositId) public view override returns(string memory) { 
        string memory message;
        AssetType depType = depositType_(depositId);
        if(depType == AssetType.ERC20) { message = "Asset Class: Token"; }
        if(depType == AssetType.ERC721) { message = "Asset Class: NFT"; }
        else { message = "Asset Class: Undefined"; }  
        return message; } 
        
    function statusOf(uint depositId) public view override returns(string memory) { 
         DepositState status = statusOf_(depositId);
         string memory message;
        if(status == DepositState.Deposited) { message = "Status: Deposited"; } 
        if(status == DepositState.Withdrawn) { message = "Status: Withdrawn"; } 
        if(status == DepositState.Claimed) { message = "Status: Claimed"; } 
        else { message = "Undefined"; } 
        return message; } }