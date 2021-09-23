// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev adapted Ownable.sol to contain control interface for NFT.
 * AUTHOR: CAT6#2699
 */
interface OwnableByTokenInterface {
    event OverrideTokenReassigned(address, uint);
    event AdminTokenReassigned(address, uint);
    
    function owner() external view returns(address);
    function overrideOwner() external view returns(address);
    function adminToken() external view returns(address, uint);
    function adminOverrideToken() external view returns(address, uint); 
    
    function oo_reassignAdminToken(address tokenAddress, uint tokenId) external returns(address, uint);
    function ooo_reassignAdminToken(address tokenAddress, uint tokenId) external returns(address, uint);
    function ooo_reassignOverrideToken(address tokenAddress, uint tokenId) external returns(address, uint);
    function od_initializeOwnership(address adminTokenAddress, uint adminTokenId, address overrideTokenAddress, uint overrideTokenId) external returns(address, uint, address, uint); } 
 
abstract contract OwnableByToken is OwnableByTokenInterface {
    ERC721 private _overrideToken;
    uint private _overrideTokenId;
    ERC721 private _adminToken;
    uint private _adminTokenId;
    address private _deployer;

    /**
    * @dev Sets the values for {adminTokenContract_} and {tokenId}
    */
    constructor() { _deployer = msg.sender; }
    
    /**
    * @dev Require _overrideToken.ownerOf()
    */
    modifier onlyOverride() {
        require(_overrideToken.ownerOf(_overrideTokenId) == msg.sender, "ERROR: msg.sender != ownerOf(_adminToken)");
        _; }
    function requireOverride() internal view { require(_overrideToken.ownerOf(_overrideTokenId) == msg.sender, "ERROR: msg.sender != ownerOf(_adminToken)"); }
        
    /**
    * @dev Require _adminToken.ownerOf()
    */
    modifier onlyOwner() {
        require(_adminToken.ownerOf(_adminTokenId) == msg.sender, "ERROR: msg.sender != ownerOf(_adminToken)");
        _; }
    function requireOwner() internal view { require(_adminToken.ownerOf(_adminTokenId) == msg.sender, "ERROR: msg.sender != ownerOf(_adminToken)"); }
        
    /**
    * @dev prevents user from fucking this up by checking for approval to address(this).
    */    
    modifier isApproved(address tokenAddress, uint tokenId) {
        require(ERC721(tokenAddress).getApproved(tokenId) == address(this), "ERROR: address(this) Not Approved Spender");
        _; }
    
    /*
     *@dev public view functions
     */
    function owner() public view override returns(address) { return _adminToken.ownerOf(_adminTokenId); }
    function overrideOwner() public view override returns(address) { return _adminToken.ownerOf(_adminTokenId); }
    function adminToken() public view override returns(address, uint) { return (address(_adminToken), _adminTokenId); }
    function adminOverrideToken() public view override returns(address, uint) { return (address(_adminToken), _adminTokenId); } 

    /**
    * @dev register different ERC721 token as tokenAddress
    * 
    * @param tokenAddress address of new _adminToken
    * @param tokenId unique id associated with _adminToken to identify owner
    */
    function oo_reassignAdminToken(address tokenAddress, uint tokenId) 
    public override
    onlyOwner isApproved(tokenAddress, tokenId) 
    returns(address, uint) {
        _adminToken = ERC721(tokenAddress);
        _adminTokenId = tokenId;
        emit AdminTokenReassigned(address(_adminToken), _adminTokenId); 
        
        return (address(_adminToken), _adminTokenId); }
    /**
    * @dev register different ERC721 token as tokenAddress by override token
    */
    function ooo_reassignAdminToken(address tokenAddress, uint tokenId) 
    public override
    onlyOverride isApproved(tokenAddress, tokenId) 
    returns(address, uint) {
        _adminToken = ERC721(tokenAddress);
        _adminTokenId = tokenId;
        emit AdminTokenReassigned(address(_adminToken), _adminTokenId); 
        
        return (address(_adminToken), _adminTokenId); }
        
    /**
    * @dev register different ERC721 token as tokenAddress
    * 
    * @param tokenAddress address of new _adminToken
    * @param tokenId unique id associated with _adminToken to identify owner
    */
    function ooo_reassignOverrideToken(address tokenAddress, uint tokenId) 
    public override
    onlyOverride isApproved(tokenAddress, tokenId) 
    returns(address, uint) {
        _overrideToken = ERC721(tokenAddress);
        _overrideTokenId = tokenId;
        emit OverrideTokenReassigned(address(_overrideToken), _overrideTokenId); 
        
        return (address(_overrideToken), _overrideTokenId); }
        
    /**
    * @dev register different ERC721 token as tokenAddress
    * 
    * @param adminTokenAddress address of new _adminToken
    * @param adminTokenId unique id associated with _adminToken to identify owner
    * @param overrideTokenAddress address of new _overrideTokeowner
    * @param overrideTokenId unique id associated with _override token to identify owner
    */
    function od_initializeOwnership(address adminTokenAddress, uint adminTokenId, address overrideTokenAddress, uint overrideTokenId) 
    public override
    isApproved(adminTokenAddress, adminTokenId) isApproved(overrideTokenAddress, overrideTokenId) 
    returns(address, uint, address, uint) {
        require(_deployer == msg.sender, "ERROR: msg.sender != _deployer");
        _adminToken = ERC721(adminTokenAddress);
        _adminTokenId = adminTokenId;
        _overrideToken = ERC721(overrideTokenAddress);
        _overrideTokenId = overrideTokenId;
        delete _deployer;
        emit AdminTokenReassigned(adminTokenAddress, adminTokenId); 
        emit OverrideTokenReassigned(address(_overrideToken), _overrideTokenId); 
        
        return (address(_adminToken), _adminTokenId, address(_overrideToken), _overrideTokenId); }
}