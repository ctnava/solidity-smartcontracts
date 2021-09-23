// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./MultiAssetVault.sol";

// Contract by CAT6#2699 
interface IMAOM is IMAV{
    function _viewOffers(uint depositId) external view returns(uint[] memory)
}

abstract contract MultiAssetOfferMarket is MultiAssetVault, IMAOM { 
    mapping(uint => uint[]) internal _offers; 
    
    /**
     * @dev Throws if caller is depositor
     */     
    modifier notDepositer(uint depositId) { require(depositorOf(depositId) != msg.sender, "ERROR: Caller not depositor"); 
        _; }
        
///////////////// NOTE: Human Readable/Interactable ==> function() || API View Functions ==> _function() ||  Internal View Only ==> function_() /////////////////

    
    
    function evenMorePruning_(uint[] memory depositArray, uint index) internal virtual {  }
    function additionalPruning_(uint[] memory depositArray, uint index) internal virtual override { 
        delete _offers[depositArray[index]]; 
        evenMorePruning_(depositArray, index); } 
}
 
        // WETH // Rinkeby // (Source: https://app.uniswap.org/#/swap)
        _paymentMethod[0] = PaymentMethod(ERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab), AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)); 
        // WBTC // Rinkeby // (Source: https://app.uniswap.org/#/swap)
        _paymentMethod[1] = PaymentMethod(ERC20(0x577D296678535e4903D59A4C929B718e1D575e0A), AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404));
        // LINK // Rinkeby // (Source: https://app.compound.finance/)
        _paymentMethod[2] = PaymentMethod(ERC20(0x01BE23585060835E02B77ef475b0Cc51aA1e0709), AggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623));
        // USDC // Rinkeby // (Source: https://app.compound.finance/)
        _paymentMethod[3] = PaymentMethod(ERC20(0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b), AggregatorV3Interface(0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB)); 
        // DAI // Rinkeby // (Source: https://app.compound.finance/)
        _paymentMethod[4] = PaymentMethod(ERC20(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa), AggregatorV3Interface(0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF));
        _paymentMethodId = 4;