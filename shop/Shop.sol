// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Inventory.sol";

/**
 * @dev SHOP MODULE
 * AUTHOR: CAT6#2699
 */
interface ShopInterface {
    
    struct Transaction {
        string itemName;
        uint time;
        address token;
        uint rawValue; } }

abstract contract Shop is ShopInterface, PricedInventory {
    event TransactionRegistered(uint);
    event TransactionSuccessful(uint);

    mapping(uint => Transaction) private transaction;
    uint private txIds;
    function _txids() internal view returns(uint) { return txIds; }
    function _transaction(uint txid) internal view returns(Transaction memory) { return transaction[txid]; }
    
    /** 
     * @dev OVERRIDE THIS FUNCTION TO DELIVER APPROPRIATE TOKEN OR NFT
     */     
    function _deliver(uint categoryId, uint collectionId) internal virtual returns(uint) { 
        return 0; }
    /** 
     * @return txId
     */ 
    function _processPayment(uint categoryId, uint collectionId, uint pairId) internal returns(uint, uint) {
        ERC20 token = _contractPair(pairId).token; 
        uint rawTokenValue = _fetchPrice(categoryId, collectionId, pairId);
        require(token.allowance(msg.sender, address(this)) >= rawTokenValue && token.balanceOf(msg.sender) >= rawTokenValue, "ERROR: Insufficient Balance/Allowance");
        token.transferFrom(msg.sender, address(this), rawTokenValue); 
        transaction[txIds] = Transaction(_item(categoryId,collectionId).name, block.timestamp, address(_contractPair(pairId).token), rawTokenValue);
        txIds++;
        emit TransactionRegistered(txIds);
        uint output = _deliver(categoryId, collectionId);
        emit TransactionSuccessful(txIds); 
        return (txIds, output); }  
    
    function _erc721xferProtocol(ERC721 nft, uint uid) internal virtual { nft.transferFrom(address(this), msg.sender, uid); }     
    
    function _erc20xferProtocol(ERC20 token) internal virtual { token.transferFrom(address(this), msg.sender, token.balanceOf(address(this))); }
    
    function _withdraw721(address nftAddress, uint uid) internal {
        ERC721 nft = ERC721(nftAddress);
        _erc721xferProtocol(nft, uid); }
    
    function _withdrawSpecific20(address tokenAddress) internal { 
        ERC20 token = ERC20(tokenAddress);
        if(token.allowance(address(this),address(this)) <= halfMaxUint) { 
            token.approve(address(this), almostMaxUint); }
        _erc20xferProtocol(token); }
        
    function _withdrawAll20() internal { 
        for(uint i = 1; i <= _contractPairIds(); i++) { 
            ERC20 token = _contractPair(i).token;
            if(token.balanceOf(address(this)) > 0) {
                if(token.allowance(address(this),address(this)) <= halfMaxUint) { 
                    token.approve(address(this), almostMaxUint); }
                _erc20xferProtocol(token); } } }
}