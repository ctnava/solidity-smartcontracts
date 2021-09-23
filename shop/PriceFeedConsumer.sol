// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library StringUtils { function _compareStrings(string memory a, string memory b) internal pure returns (bool) { return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b)))); } }

/**
 * @dev PRICEFEED MODULE
 * AUTHOR: CAT6#2699
 */
interface PriceFeedConsumerInterface {
    struct ContractPair {
        ERC20 token;
        AggregatorV3Interface priceFeed; } }

abstract contract PriceFeedConsumer is PriceFeedConsumerInterface {
    using StringUtils for string;
    uint constant halfMaxUint = 2**255;
    uint constant sub1 = halfMaxUint-1;
    uint constant almostMaxUint = halfMaxUint + sub1;
    
    mapping(uint => ContractPair) private contractPair;
    uint private contractPairIds; 
    function _contractPair(uint pairId) internal view returns(ContractPair memory) { return (contractPair[pairId]); } 
    function _contractPairIds() internal view returns(uint) { return contractPairIds; } 
    
    /**
     * @return newest address pair
     */ 
    function _addContractPair(address tokenAddress, address priceFeedAddress) internal returns(uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        //string memory description = priceFeed.description();
        ERC20 token = ERC20(tokenAddress);
        //require(_compareStrings(token.symbol(), sliceOfDescription), "ERROR: Invalid Contract Pair");
        if(token.allowance(address(this),address(this)) <= halfMaxUint) { token.approve(address(this), almostMaxUint); }
        contractPairIds++;
        contractPair[contractPairIds] = ContractPair(token, priceFeed);
        return contractPairIds; }
    /**
     * @return success condition
     */ 
    function _updateContractPair(uint pairId, address tokenAddress, address priceFeedAddress) internal returns(bool) { 
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        //string memory description = priceFeed.description();
        ERC20 token = ERC20(tokenAddress);
        //require(_compareStrings(token.symbol(), sliceOfDescription), "ERROR: Invalid Contract Pair");
        contractPair[pairId] = ContractPair(token, priceFeed);
        address ofToken; 
        address ofFeed; 
        ofToken = address(_contractPair(pairId).token);
        ofFeed = address(_contractPair(pairId).token);
        return (ofToken == tokenAddress && ofFeed == priceFeedAddress); }
    /**
     * @return Tokens per USD/ETH (Raw Value)
     */ 
    function _fetchExchangeRate(ContractPair memory thisMethod) internal view returns(uint) {
        ERC20 token = thisMethod.token; 
        AggregatorV3Interface priceFeed = thisMethod.priceFeed;
        uint feedExp = 10 ** priceFeed.decimals(); 
        uint tokenExp = 10 ** token.decimals();
        uint feedExpSquared = feedExp ** 2;
        (, int price,,,) = priceFeed.latestRoundData();
        uint feedRawPrice = uint(price);
        uint feedRawPriceSquared = feedRawPrice ** 2;
        uint helper;
        uint divisible;
        uint tokensPerUnit;
        if(tokenExp >= feedExp) {
            helper = tokenExp/feedExp;
            uint indivisible = feedRawPrice * helper;    
            divisible  = indivisible * feedExpSquared; }
        else{
            helper = feedExp*tokenExp; 
            divisible = feedRawPrice * helper;}
        tokensPerUnit = divisible/feedRawPriceSquared;
        return  tokensPerUnit; } }