// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./MultiAssetEscrow.sol";
import "./ExtendedMAV.sol";

// Contract by CAT6#2699
interface Extended_IMAE is Extended_IMAV {
    function viewRequest(uint depositId) external view returns(string memory);
    function _viewRequest(uint depositId) external view returns(string memory);
    function offerType(uint depositId) external view returns(string memory);
    function typeOfRequest(uint depositId) external view returns(string memory); }
    
abstract contract Extended_MultiAssetEscrow is MultiAssetEscrow, Extended_IMAE {
    function viewRequest(uint depositId) public view override returns (string memory) { }
    function _viewRequest(uint depositId) public view override returns (string memory) { } 

    function offerType(uint depositId) public view override returns(string memory) {
        OfferType esType = offerType_(depositId);
        if(esType == OfferType.ERC20_ERC20) { return "TOKEN4TOKEN"; }
        if(esType == OfferType.ERC20_ERC721) { return "TOKEN4NFT"; }
        if(esType == OfferType.ERC20_specificERC721) { return "TOKEN4specificNFT"; }
        if(esType == OfferType.ERC721_ERC20) { return "NFT4TOKEN"; }
        if(esType == OfferType.ERC721_ERC721) { return "NFT4NFT"; }
        if(esType == OfferType.ERC721_specificERC721) { return "NFT4specificNFT"; }
        else { return "Undefined"; } } 

    function typeOfRequest(uint depositId) public view override returns(string memory) { 
        string memory message;
        AssetType depType = depositType_(depositId);
        if(depType == AssetType.ERC20) { message = "Asset Class: Token"; }
        if(depType == AssetType.ERC721) { message = "Asset Class: NFT"; }
        else { message = "Asset Class: Undefined"; }  
        return message; } }