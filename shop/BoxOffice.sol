// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Shop.sol";
import "./CuneiformToken.sol";
import "./OwnableByToken.sol";

/**
 * @dev Box Office Contract
 * AUTHOR: CAT6#2699
 */
interface BoxOfficeInterface {
    event NewTicket(uint);
    
    function purchaseTicket(uint mediaId, uint ticketType, uint paymentMethod) external;
    function cashOut() external;
}

contract BoxOffice is BoxOfficeInterface, Shop, OwnableByToken {
    CuneiformToken internal _ticketContract;
    
    constructor(address ticketContract) { _ticketContract = CuneiformToken(ticketContract); } 
        
        
    function _deliver(uint mediaId, uint ticketType) 
    internal override 
    returns(uint) {
        uint ticketId = _ticketContract.issueTicket(msg.sender, mediaId, ticketType);
        return ticketId;  }
        
    function purchaseTicket(uint mediaId, uint ticketType, uint paymentMethod) 
    public override { 
        uint ticketId;
        (, ticketId) = _processPayment(mediaId, ticketType, paymentMethod); 
        emit NewTicket(ticketId); } 
    
    function cashOut() public override onlyOwner { _withdrawAll20(); }
}

contract TestNetBoxOffice is BoxOffice {
    constructor(address nftContract, address adminTokenAddress, uint adminTokenId, address overrideTokenAddress, uint overrideTokenId)  BoxOffice(nftContract) {
        //Rinkeby
        address usdc = (0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b); // (Source: https://app.compound.finance/)
        address usdc_usd = (0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB);
        _addContractPair(usdc, usdc_usd);
        address weth = (0xc778417E063141139Fce010982780140Aa0cD5Ab); // (Source: https://app.uniswap.org/#/swap)
        address eth_usd = (0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        _addContractPair(weth, eth_usd); 
        address wbtc = (0x577D296678535e4903D59A4C929B718e1D575e0A); // (Source: https://app.uniswap.org/#/swap)
        address btc_usd = (0xECe365B379E1dD183B20fc5f022230C044d51404);
        _addContractPair(wbtc, btc_usd); 
        address link = (0x01BE23585060835E02B77ef475b0Cc51aA1e0709); // (Source: https://rinkeby.chain.link/)
        address link_usd = (0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);
        _addContractPair(link, link_usd );
        address dai = (0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa); // (Source: https://app.compound.finance/)
        address dai_usd = (0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF);
        _addContractPair(dai, dai_usd); 
        
        od_initializeOwnership(adminTokenAddress, adminTokenId, overrideTokenAddress, overrideTokenId); }
}