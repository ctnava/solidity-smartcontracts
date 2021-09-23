// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./MultiAssetVault.sol";

// Contract by CAT6#2699
interface IMAE is IMAV{
    enum OfferType { Undefined , ERC20_ERC20, ERC20_ERC721, ERC20_specificERC721, ERC721_ERC20, ERC721_ERC721, ERC721_specificERC721 }
    
    struct RequestMetadata {
        AssetType asset;
            address assetAddress;
            uint[2] integers; 
            address participant;
        OfferType offer; }
        
    function participantOf(uint depositId) external view returns(address);
    function requestedAssetAddress(uint depositId) external view returns(address);
    function _requestType(uint depositId) external view returns(uint);
    function _requestValue(uint depositId) external view returns(uint);
            function _requestPreDec(uint depositId) external view  returns(uint);
            function _requestPostDec(uint depositId) external view  returns(uint);
            
    function requestIsSpecific(uint depositId) external view returns(bool);
    function _offerType(uint depositId) external view returns(uint); 
    function offerIsPrivate(uint depositId) external view returns(bool);
    
    function activeRequestsOf(address user) external view returns(uint[] memory); 
    function purchaseHistoryOf(address user) external view returns(uint[] memory); 
    function depositsSoliciting(address user) external view returns(uint[] memory); } 

abstract contract MultiAssetEscrow is MultiAssetVault, IMAE { 
    RequestMetadata[] internal _request;  
    
    /**
     * @dev Throws if caller is depositor
     */     
    modifier notDepositor(uint depositId) { require(depositorOf(depositId) != msg.sender, "ERROR: Caller is depositor"); 
        _; }
    
    /**
     * @dev Throws if the escrow is not in expected state
     */
    modifier modifiableRequest(uint depositId) { require(statusOf_(depositId) == DepositState.Deposited, "ERROR: Escrow cannot be modified.");
        _; }
    
///////////////// NOTE: Human Readable/Interactable ==> function() || API View Functions ==> _function() ||  Internal View Only ==> function_() /////////////////
    function viewRequest_(uint depositId) internal view returns(RequestMetadata memory) { return _request[depositId]; }
    
    function requestType_(uint depositId) internal view returns(AssetType) { 
        if(offerType_(depositId) != OfferType.ERC20_ERC20 && offerType_(depositId) != OfferType.ERC20_ERC721) { return AssetType.ERC20; }
        else { return AssetType.ERC721; } }
    function requestNFT_(uint depositId) internal view returns(ERC721) { return ERC721(viewRequest_(depositId).assetAddress); }
        function requestInt_(uint depositId) internal view returns(uint) { return viewRequest_(depositId).integers[0]; }
    function requestToken_(uint depositId) internal view returns(ERC20) { return ERC20(viewRequest_(depositId).assetAddress); }
        function requestUnits_(uint depositId) internal view returns(uint) { return viewRequest_(depositId).integers[1]; }
            function requestedDecimals_(uint depositId) internal view returns(uint) { return requestToken_(depositId).decimals(); }
    function offerType_(uint depositId) internal view returns(OfferType)  { return viewRequest_(depositId).offer; }
    function classifyOfferType_(bool d_isNFT, address d_asset, bool r_isNFT, bool r_isSpecific, address r_asset) internal pure returns(OfferType) { 
        if(!r_isNFT) {
            if(r_asset != d_asset) { return OfferType.Undefined; }
            if(!d_isNFT) {
                return OfferType.ERC20_ERC20; }
            else {
                return OfferType.ERC721_ERC20; } }
        else { 
            if(r_isSpecific) { 
                if(!d_isNFT) { 
                    return OfferType.ERC20_specificERC721; }
                else {
                    return OfferType.ERC721_specificERC721; } } 
            else {
                if(!d_isNFT) {
                    return OfferType.ERC20_ERC721; }
                else {
                    return OfferType.ERC721_ERC721; } } } }
    
    function requestedAssetAddress(uint depositId) public view override returns(address) { return viewRequest_(depositId).assetAddress; }
    function _requestType(uint depositId) public view override returns(uint) { return uint(viewRequest_(depositId).asset); }
    function _requestValue(uint depositId) public view override returns(uint) { 
            uint value;
            uint corrected = depositedDecimals_(depositId) - requestUnits_(depositId);
            if(requestType_(depositId) == AssetType.ERC20) { value = requestInt_(depositId) * 10 ** corrected; }
            else { value = depositedInt_(depositId); }
            return value; }
            function _requestPreDec(uint depositId) public view override returns(uint) { return (_requestValue(depositId) / requestToken_(depositId).decimals()); }
            function _requestPostDec(uint depositId) public view override returns(uint) { return (_requestValue(depositId) % requestToken_(depositId).decimals()); }
    
    function participantOf(uint depositId) public view override returns(address) { return viewRequest_(depositId).participant; } 
    function _offerType(uint depositId) public view override returns(uint) { return uint(offerType_(depositId)); } 
    function requestIsSpecific(uint depositId) public view override returns(bool) { 
        return (offerType_(depositId) == OfferType.ERC20_specificERC721 || offerType_(depositId) == OfferType.ERC721_specificERC721); }
    function offerIsPrivate(uint depositId) public view override returns(bool) { return (depositorOf(depositId) != participantOf(depositId)); }
    
    /**
     * @dev Returns array of activity by user
     */    
    function activeRequestsOf(address user)
    public view override
    returns(uint[] memory) {
        uint[] memory activeDeposits = activeDepositsOf(user);
        uint[] memory activeRequests;
        uint index;
        for(uint i = 0; i < activeDeposits.length; i++) {
            if(statusOf_(i) == DepositState.Deposited && requestedAssetAddress(i) != address(0)) {  
                activeRequests[index] = i; 
                index++; } }
        return activeRequests; }
    function purchaseHistoryOf(address user)
    public view override
    returns(uint[] memory) {
        uint[] memory activeDeposits = activeDepositsOf(user);
        uint[] memory activeRequests;
        uint index;
        for(uint i = 0; i < activeDeposits.length; i++) {
            if(statusOf_(i) == DepositState.Claimed && requestedAssetAddress(i) != address(0)) {  
                activeRequests[index] = i; 
                index++; } }
        return activeRequests; }
    function depositsSoliciting(address user)
    public view override 
    returns(uint[] memory) {
        uint[] memory featured;
        uint index;
        for(uint i = 1; i < _depositIds; i++) {
            bool userIsDepositor = (user == participantOf(i));
            if(userIsDepositor) { 
                featured[index] = i;
                index++; } }
        return featured; }
    
    /** 
     * @dev Creates a new escrow. Puts assetAddress item into contract custody
     *  
     * @param d_isNFT defines the deposited assetType as NFT or not
     * @param d_asset The contract address of ERC20 or ERC721 to put into DepositMetadata.
     * @param d_integer The id or amount of requested asset
     * @param d_units determines how many decimals to leave out during transfer
     * (e.g. 0 to send whole coins, 1 to send "eDimes", 2 to send "ePennies" )
     * 
     * @param r_isNFT defines the requested assetType as NFT or not
     * @param r_isSpecific defines the requested assetType as specific id of NFT
     * @param r_asset The contract address of ERC20 or ERC721 to put into RequestMetadata.
     * @param r_integer The id or amount of requested asset
     * @param r_units determines how many decimals to leave out during transfer
     * (e.g. 0 to send whole coins, 1 to send "eDimes", 2 to send "ePennies" )
     * @param participant Sets participant address.
     * (OPTIONAL) address(0) if offer is open to public. 
     *
     * @return overall amount of deposits/ depositId
     */    
    function openEscrow(bool d_isNFT, address d_asset, uint d_integer, uint d_units, bool r_isNFT, bool r_isSpecific, address r_asset, uint r_integer, uint r_units, address participant) 
    public 
    nonZero(participant) nonZero(d_asset) nonZero(r_asset)
    returns(uint) { 
        OfferType thisOffer = classifyOfferType_(d_isNFT, d_asset, r_isNFT, r_isSpecific, r_asset);
        require(thisOffer != OfferType.Undefined, "ERROR: Invalid OfferType");
        uint depositId = makeDeposit(d_isNFT, d_asset, d_integer, d_units);
        makeRequest(depositId, r_isNFT, r_isSpecific, r_asset, r_integer, r_units, participant);
        
        return depositId; }
        
    function beforeCall_() internal view virtual {  }
    function afterSuccess_() internal virtual {  }        
    /*
     *  @dev define Request Metadata
     *  NOTE: separated this into a two-step function because the call stack was too deep
     *  
     *  @param isNFT defines the requested assetType as NFT or not
     *  @param isSpecific defines the requested assetType as specific id of NFT
     *  @param participant Sets participant address.
     *  (OPTIONAL) address(0) if offer is open to public. 
     *  @param assetAddress the contract address for payment.
     *
     *  @return updated values
     */
    function makeRequest(uint depositId, bool isNFT, bool isSpecific, address asset, uint integer, uint units, address participant) 
    public
    onlyDepositor(depositId) nonZero(participant) modifiableRequest(depositId) nonZero(asset) {
        // Bounce Bad Arguments
        beforeCall_();
        bool d_isNFT = (depositType_(depositId) == AssetType.ERC721);
        address d_asset = depositedAssetAddress(depositId);
        OfferType thisOffer = classifyOfferType_(d_isNFT, d_asset, isNFT, isSpecific, asset);
        bool isPrivate = (depositorOf(depositId) != participant); 
        // Store Request Type 
        if(thisOffer != OfferType.Undefined) {
            if(thisOffer == OfferType.ERC20_ERC20 || thisOffer == OfferType.ERC721_ERC20) { 
                ERC20 reqToken = ERC20(asset);
                uint reqDecimals = reqToken.decimals() - units;
                uint reqUnits = 10 ** reqDecimals;
                uint reqValue = integer * reqUnits; 
                require(reqValue > 0, "ERROR: number || integer == 0."); 
            if(isPrivate) { require(reqToken.balanceOf(participant) >= reqValue, "ERROR: Participant balance too low"); }
                _request[depositId] = RequestMetadata(AssetType.ERC20, asset, [integer, units], participant, thisOffer); }
            else {
                ERC721 reqNFT = ERC721(asset);
                if(isPrivate) { require(reqNFT.balanceOf(participant)  > 0, "ERROR: Participant owns none of this assetAddress");
                if(thisOffer == OfferType.ERC20_ERC721 || thisOffer == OfferType.ERC721_ERC721) { 
                    uint[2] memory empty;
                    _request[depositId] = RequestMetadata(AssetType.ERC721, asset, empty, participant, thisOffer); }
                else {
                    require(reqNFT.ownerOf(integer) != address(0), "ERROR: doesn't exist.");
                    if(isPrivate) { require(reqNFT.ownerOf(integer) == participant, "ERROR: Participant not owner"); }
                    _request[depositId] = RequestMetadata(AssetType.ERC721, asset, [integer, 0], participant, thisOffer); } } } } 
        else { require(thisOffer != OfferType.Undefined, "ERROR: OfferType.Undefined"); } 
        afterSuccess_(); }
    
      /**
     * @dev Executes a trade. Must have approved this contract to transfer the
     * amount of currency specified to the poster. Transfers ownership of the
     * item to the filler.
     * 
     * @param depositId The id of an existing DepositMetadata
     * @param approvedTokenId id of preapproved NFT
     * 
     */
    function fulfillRequest(uint depositId, uint approvedTokenId) 
    public
    validDeposit(depositId) notDepositor(depositId) modifiableRequest(depositId) { 
        beforeCall_();
        
        address depositer = depositorOf(depositId);
        address participant = participantOf(depositId);
        bool isPrivate = offerIsPrivate(depositId);
        if (isPrivate){ 
            require(participant == msg.sender, "ERROR: Caller not whitelisted"); }
        // Move Assets
        if (requestType_(depositId) == AssetType.ERC20) { 
            requestToken_(depositId).transferFrom(msg.sender, depositer, _requestValue(depositId)); }
        else { 
            if(requestType_(depositId) == AssetType.ERC721) { 
                requestNFT_(depositId).transferFrom(msg.sender, depositer, _requestValue(depositId)); }
            else { 
                requestNFT_(depositId).transferFrom(msg.sender, depositer, approvedTokenId); } 
                requestNFT_(depositId).ownerOf(_requestValue(depositId)) == depositer; }
                
        if(participant == address(0)) { _request[depositId].participant = msg.sender; }
        deliverTo_(depositId, msg.sender);
        
        _deposit[depositId].status = DepositState.Claimed;
        afterSuccess_(); // Optional Override
        
        emit Broadcast("Escrow Finalized (Request Fulfilled) ||", depositId); }
        
    function evenMorePruning_(uint[] memory depositArray, uint index) internal virtual {  }
    function additionalPruning_(uint[] memory depositArray, uint index) internal virtual override { 
        delete _request[depositArray[index]]; 
        evenMorePruning_(depositArray, index); } 
}
 
