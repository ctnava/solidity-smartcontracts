// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./PriceFeedConsumer.sol";

/**
 * @dev INVENTORY MODULE
 * AUTHOR: CAT6#2699
 */
interface InventoryInterface {
    
    struct CategoryMetadata {
        string name;
        bool isValid;
        Item[] collection; }
        
    struct Item {
        string name;
        uint price;
        bool flatrateIsGas; } }

abstract contract Inventory is InventoryInterface  {
    using StringUtils for string;
    
    mapping(uint => CategoryMetadata) private inventory; // true ==> units(price) = wei || false ==> units(price) = usdPennies
    uint private categoryIds;
    function _categoryIds() internal view returns(uint) { return categoryIds; }
    function _categoryMetadata(uint categoryId) internal view returns(CategoryMetadata memory) { return inventory[categoryId]; }
    function _item(uint categoryId, uint collectionId) internal view returns(Item memory) { return _categoryMetadata(categoryId).collection[collectionId]; } 
    
    /**
     * @return categoryId
     */ 
    function _addCategory(string memory categoryName, string memory name, uint price, bool flatrateIsGas) internal returns(uint) { 
        categoryIds++;
        Item[] memory newCollection;
        newCollection[0] = Item(name, price, flatrateIsGas);
        inventory[categoryIds] = CategoryMetadata(categoryName, true, newCollection); 
        return (categoryIds); }
    /**
     * @return success condition
     */     
    function _editCategory(uint categoryId, string memory name, bool isValid) internal returns(bool) {  
        inventory[categoryId].name = name;
        inventory[categoryId].isValid = isValid;
        return(StringUtils._compareStrings(_categoryMetadata(categoryId).name, name) && _categoryMetadata(categoryId).isValid == isValid); }
    /**
     * @return collectionId
     */     
    function _addItemToCategory(uint categoryId, string memory name, uint price, bool flatrateIsGas) internal returns(uint) { 
        inventory[categoryId].collection.push(Item(name, price, flatrateIsGas)); 
        return (_categoryMetadata(categoryId).collection.length); }
    /**
     * @return success condition
     */ 
    function _editItemInCategory(uint categoryId, uint collectionId, string memory name, uint price, bool flatrateIsGas) internal returns(bool) { 
        inventory[categoryId].collection[collectionId] = Item(name, price, flatrateIsGas);
        return (StringUtils._compareStrings(_item(categoryId, collectionId).name, name) && 
        _item(categoryId, collectionId).price == price && _item(categoryId, collectionId).flatrateIsGas == flatrateIsGas); } }
        
contract PricedInventory is PriceFeedConsumer, Inventory {
    /**
     * @return Tokens per Item (Raw Value)
     */ 
    function _fetchPrice(uint categoryId, uint collectionId, uint pairId) public view returns(uint) { 
        require(categoryId < _categoryIds() && collectionId <= _categoryMetadata(categoryId).collection.length, "ERROR: Invalid seriesId");
        require(pairId >= 0 && pairId <= _contractPairIds(), "ERROR: Invalid nftType");
        uint tokensPerUnit = _fetchExchangeRate(_contractPair(pairId));
        uint assetUnitValue = _item(categoryId, collectionId).price; 
        uint tokensPerAsset;
        if(_item(categoryId, collectionId).flatrateIsGas){ 
            uint feedExp = 10 ** _contractPair(pairId).priceFeed.decimals(); 
            uint tokensPerHundredQuintillion = assetUnitValue * tokensPerUnit;
            tokensPerAsset = tokensPerHundredQuintillion/feedExp; }
        else{
            uint tokensPerHundred = assetUnitValue * tokensPerUnit;
            tokensPerAsset = tokensPerHundred/100; }
        return  tokensPerAsset; } 
}