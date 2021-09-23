// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Test Token Base
 * AUTHOR: CAT6#2699
 */
//------------------------------------------------------------ Debugging Module
contract Debugger is Ownable { 
    address private _contractToDebug;
    
    constructor(address contractAddress) { _contractToDebug = contractAddress; }
    
    function contractToDebug()public view returns (address) { return _contractToDebug; }
    function o_setContractToDebug(address contractAddress) public onlyOwner returns(address) { _contractToDebug = contractAddress;
        return _contractToDebug; } }
        
//------------------------------------------------------------ Collectibles
contract FreelyMintableNFT is ERC721, Ownable { 
    uint private _tokenIds;
    string private _currentBaseURI = "http://localhost:9000/ticket/";

    constructor(string memory optionalURI, string memory name, string memory symbol) ERC721(name, symbol) { 
        if(compareStrings(optionalURI, "")) { _currentBaseURI = optionalURI; } }
        
    function compareStrings(string memory a, string memory b) public pure returns (bool) { return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b)))); }
    
    function _baseURI()internal view override returns (string memory) { return _currentBaseURI; } 
    function o_setBaseURI(string memory newBaseURI) public onlyOwner returns(string memory) { _currentBaseURI = newBaseURI;
        return _currentBaseURI; } 
        
    /**
     * @dev Returns user inventory as array of tokenIds
     */
    function fetchInventory(address user) public view
    returns(uint256[] memory) {
        uint tokenCount = balanceOf(user);
        if (tokenCount == 0) { return new uint256[](0); } 
        else {
            uint[] memory result = new uint256[](tokenCount);
            uint resultIndex;
            for (uint tokenId = 1; tokenId <= _tokenIds; tokenId++) {
                if (ownerOf(tokenId) == user) {
                    result[resultIndex] = tokenId;
                    resultIndex++; } }

        return result; } }

    /**
     * @dev Mints the msg.sender a new token and returns its id
     */ 
    function quickMint() public returns(uint) {
        _tokenIds++;
        _mint(msg.sender, _tokenIds); 
        
        return _tokenIds; } 
        
    /** 
     * @dev Approves all owned tokens to 'spender' and returns array of approved tokens
     */
    function approveAll(address spender) public returns(uint[] memory) {
        uint[] memory collection = fetchInventory(msg.sender);
        for (uint i; i < collection.length; i++) { _approve(spender, collection[i]); }
        
        return collection; } }

//------------------------------------------------------------ TestNFTs
abstract contract TestNFT is FreelyMintableNFT, Debugger {
    /**
     * @dev approveAll, but with 'spender' assigned to contractToDebug
     */ 
    function quickApproveAll() 
    public 
    returns(uint[] memory) { 
        uint[] memory collection = approveAll(contractToDebug()); 
        
        return collection; } }

//------------------------------------------------------------ Tokens
contract FreelyMintableToken is ERC20 {
    uint private standardAmount = 10000 * 10 ** decimals();
    
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {  }
        
    function quickMint() public returns(bool) { 
        uint expected = totalSupply() + standardAmount;
        _mint(msg.sender, standardAmount); 
        
        return (expected == totalSupply()); } }
        
//------------------------------------------------------------ Test Tokens
abstract contract TestToken is FreelyMintableToken, Debugger {
    
    function quickApproveAll() public returns(bool) { 
        _approve(msg.sender, contractToDebug(), balanceOf(msg.sender)); 
        uint expected = balanceOf(msg.sender);
        uint returned = allowance(msg.sender, contractToDebug());
        return (returned == expected); }
}