// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Contract by CAT6#2699
interface IMAV {
    enum AssetType { Undefined, ERC20, ERC721 }
    enum DepositState { Undefined, Deposited, Withdrawn, Claimed }
    
    struct DepositMetadata {
        AssetType assetType;
            address assetAddress;
            uint[2] integers;
            address depositor; 
        DepositState status; }
    
    function depositorOf(uint depositId) external view returns(address);
    function depositedAssetAddress(uint depositId) external view returns(address);
    function _depositType(uint depositId) external view returns(uint);
    function _depositValue(uint depositId) external view returns(uint); 
        function _depositPreDec(uint depositId) external view returns(uint); 
        function _depositPostDec(uint depositId) external view returns(uint); 
        
    function _statusOf(uint depositId) external view returns(uint); 
    
    function allDepositsOf(address user) external view returns(uint[] memory); 
    function activeDepositsOf(address user) external view returns(uint[] memory); 
    function withdrawnDepositsOf(address user) external view returns(uint[] memory);
    function claimedDepositsOf(address user) external view returns(uint[] memory); 

    function _checkPrunability(uint depositId) external view returns(bool); }

abstract contract MultiAssetVault is IMAV {
    event Broadcast(string, uint);
    
    bool private _busy;
    
    uint constant half = 2 ** 255;
    uint constant almostMaxUint = half - 1 + half;
    DepositMetadata[] internal _deposit; 
    uint[] private _prunableAt; // [timestamp]
    uint internal _depositIds;
    
    /**
     * @dev Throws if the escrow is nonexistent
     */
    modifier validDeposit(uint depositId) { require(_statusOf(depositId) != 0, "ERROR: Query for nonexistent deposit.");
        _; }
        
    /**
     * @dev Throws if caller is not depositor
     */     
    modifier onlyDepositor(uint depositId) { require(depositorOf(depositId) == msg.sender, "ERROR: Caller not depositor"); 
    _; }

    modifier nonZero(address pointer) { require(pointer != address(0), "ERROR: address == address(0).");
        _; } 
    
//////////////////////////////////////// API View Functions ==> _function() ||  Internal/View Only ==> function_() //////////////////////////////////////////////
    function viewDeposit_(uint depositId) internal view returns(DepositMetadata memory) { return _deposit[depositId]; }

    function depositType_(uint depositId) internal view returns(AssetType) { return viewDeposit_(depositId).assetType; }
    function depositedNFT_(uint depositId) internal view returns(ERC721) { return ERC721(viewDeposit_(depositId).assetAddress); }
        function depositedInt_(uint depositId) internal view returns(uint) { return viewDeposit_(depositId).integers[0]; }
    function depositedToken_(uint depositId) internal view returns(ERC20) { return ERC20(viewDeposit_(depositId).assetAddress); }
        function depositedUnits_(uint depositId) internal view returns(uint) { return viewDeposit_(depositId).integers[1]; }
            function depositedDecimals_(uint depositId) internal view returns(uint) { return depositedToken_(depositId).decimals(); }
    function statusOf_(uint depositId) internal view returns(DepositState) { return viewDeposit_(depositId).status; }

    
    function depositedAssetAddress(uint depositId) public view override returns (address) { return viewDeposit_(depositId).assetAddress; }
    function _depositType(uint depositId) public view override returns (uint) { return uint(viewDeposit_(depositId).assetType); }
    function _depositValue(uint depositId) public view override returns (uint) { 
        uint value;
        uint corrected = depositedDecimals_(depositId) - depositedUnits_(depositId);
        if(depositType_(depositId) == AssetType.ERC20) { value = depositedInt_(depositId) * 10 ** corrected; }
        else { value = depositedInt_(depositId); }
        return value; }
        function _depositPreDec(uint depositId) public view override returns(uint) { return (_depositValue(depositId) / depositedToken_(depositId).decimals()); }
        function _depositPostDec(uint depositId) public view override returns(uint) { return (_depositValue(depositId) % depositedToken_(depositId).decimals()); }
        
    function depositorOf(uint depositId) public view override returns(address) { return viewDeposit_(depositId).depositor; }    
    function _statusOf(uint depositId) public view override returns(uint) { return uint(viewDeposit_(depositId).status); }

    function _checkPrunability(uint depositId) public view override returns(bool) { return (block.timestamp > _prunableAt[depositId]); }
    
    /**
     * @dev Returns array of deposits by user
     */
    function allDepositsOf(address user) 
    public view override 
    returns(uint[] memory) {
        uint[] memory deposits;
        uint index;
        for(uint i = 1; i < _depositIds; i++) {
            bool userIsDepositor = (user == depositorOf(i));
            if(userIsDepositor) { 
                deposits[index] = i;
                index++; } }
        return deposits; }
    function activeDepositsOf(address user)
    public view override
    returns(uint[] memory) {
        uint[] memory deposits = allDepositsOf(user);
        uint[] memory activeDeposits;
        uint index;
        for(uint i = 0; i < deposits.length; i++) {
            if(statusOf_(i) == DepositState.Deposited) { 
                activeDeposits[index] = i; 
                index++; } }
        return activeDeposits; }
    function withdrawnDepositsOf(address user) 
    public view override
    returns(uint[] memory) {
        uint[] memory deposits = allDepositsOf(user);
        uint[] memory withdrawals;
        uint index;
        for(uint i = 0; i < deposits.length; i++) {
            if(statusOf_(i) == DepositState.Withdrawn) { 
                withdrawals[index] = i; 
                index++; } }
        return withdrawals; }
    function claimedDepositsOf(address user) 
    public view override
    returns(uint[] memory) {
        uint[] memory deposits = allDepositsOf(user);
        uint[] memory claimed;
        uint index;
        for(uint i = 0; i < deposits.length; i++) {
            if(statusOf_(i) == DepositState.Claimed) { 
                claimed[index] = i; 
                index++; } }
        return claimed; }
            
    /**
     * @dev Delivers the deposited item from 'depositId' to 'user'
     */        
    function deliverTo_(uint depositId, address user) 
    internal {
        if(depositType_(depositId) == AssetType.ERC721) { 
            depositedNFT_(depositId).transferFrom(address(this), user, _depositValue(depositId)); 
            require(depositedNFT_(depositId).ownerOf(_depositValue(depositId)) == user); } // can potentially cause problems
        else { 
            if(depositedToken_(depositId).allowance(address(this), address(this)) == 0) { 
                depositedToken_(depositId).approve(address(this), almostMaxUint); } 
            depositedToken_(depositId).transferFrom(address(this), user, _depositValue(depositId)); }
            
        if(user == msg.sender) { _deposit[depositId].status = DepositState.Withdrawn;  }
        else {_deposit[depositId].status = DepositState.Claimed; } }
            
    /**
     * @dev Closes an Escrow. Retrieves assetAddress item from Escrow
     * 
     * @param depositId The DepositMetadata contract to close or abort.
     * 
     * @return success
     */
    function withdrawDeposit(uint256 depositId) 
    public
    validDeposit(depositId) onlyDepositor(depositId) 
    returns(bool) { 
        // Return to Sender
        deliverTo_(depositId, depositorOf(depositId));
        _prunableAt[depositId] = block.timestamp + 365 days;
        
        emit Broadcast("Deposit Withdrawn || ", depositId); 
        return (_statusOf(depositId) == 2); }
        
    /**
     * @dev Creates a new deposit. Puts assetAddress item into contract custody
     * 
     * @param isNFT Type of deposited assetType
     * @param asset The contract address of ERC20 or ERC721 to put into DepositMetadata.
     * @param integer The id or amount of escrowed assetAddress.
     * @param units determines how many decimals to leave out during transfer
     * (e.g. 0 to send whole coins, 1 to send "eDimes", 2 to send "ePennies" )
     * 
     * @return overall amount of deposits/ depositId
     */
    function makeDeposit(bool isNFT, address asset, uint integer, uint units)
    public
    nonZero(asset)
    returns(uint) {
        uint depDecimals;
        uint depValue; 
        require(!_busy, "ERROR: Vault Busy! Please Try Again.");
        
        // Take Deposit
        if(isNFT) { 
            ERC721 depNFT = ERC721(asset); 
            depNFT.transferFrom(msg.sender, address(this), integer); 
            depNFT.ownerOf(integer) == msg.sender; }
        else { 
            ERC20 depToken = ERC20(asset);
            depDecimals = depToken.decimals() - units;
            uint depUnits = 10 ** depDecimals;
            depValue = integer * depUnits; 
            depToken.transferFrom(msg.sender, address(this), depValue); 
            if(depToken.allowance(address(this), address(this)) == 0) { depToken.approve(address(this), almostMaxUint); } }
        // Process Deposit
        _busy = true;
            _depositIds ++;
            if(isNFT) { _deposit[_depositIds] = DepositMetadata(AssetType.ERC721, asset, [integer, 0], msg.sender, DepositState.Deposited); }
            else { _deposit[_depositIds] = DepositMetadata(AssetType.ERC20, asset, [integer, units], msg.sender, DepositState.Deposited); }
        _busy = false;
        
        emit Broadcast("Deposit Reqistered ||", _depositIds); 
        return _depositIds; }
    
    function callerRequirements_(uint[] memory depositArray, uint index) internal view virtual { // DEFAULT: Available to Deployers
        require(depositorOf(depositArray[index]) == msg.sender, "ERROR: Caller not depositor of escrow(s)"); }    
    function additionalPruning_(uint[] memory depositArray, uint index) internal virtual {  }    
    /**
     * @dev Prune WithdrawnDeposits
     * 
     * @return success
     */
    function pruneData(uint[] memory depositArray) 
    public
    returns(bool) { 
        for(uint i = 0; i < depositArray.length; i++){ 
            callerRequirements_(depositArray, i);
            require(_checkPrunability(i), "ERROR: > 0 deposit(s) not prunable"); }
        
        for(uint i = 0; i < depositArray.length; i++) { 
            delete _deposit[depositArray[i]]; 
            additionalPruning_(depositArray, i);
            delete _prunableAt[i]; }
            
        return true; } 
} 