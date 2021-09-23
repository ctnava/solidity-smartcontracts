// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../.././access/OwnableByToken.sol";

/**
 * @dev Auction Pseudochain
 * AUTHOR: CAT6#2699
 */
contract AuctionPseudochain is OwnableByToken {
    event Broadcast(string, uint);
    event Broadcast(string, uint, string, uint, string, uint);
    event Broadcast(string, uint, string, address, uint);

    bool busy;
    uint private _auctionIds;
        
    struct Auction {
        string classification; // "NFT", "TOKEN"
        address deployer;
            address d_token;
            uint d_int;
            uint d_decimals;
        address highestBidder;
            address r_token;
            uint highestBid;
            uint r_decimals;
        address[] participants;
        bool isPrivate;
        uint openingBid;
        uint timeOpen;
        uint timeClose;
        uint status; } //  1 == active, 2 == finalized, 3 == aborted, 4 == initialized 
    mapping(uint256 => Auction) auctionChain;
    
    struct UserData {
        uint[2][] deployed; // X == deploymentIndex || [X][0] => index || [X][1] => auctionStatus (0 == initialized, 1 == active, 2 == finalized, 3 == aborted)
        uint[2][] bids; } // X == bidIndex || [X][0] => index || [X][1] => bidderStatus (0 != highestBidder, 1 == highestBidder, 2 == winning bidder)   
    mapping(address => UserData) historyOf;
    
    constructor(address _adminContract, uint _adminUid, address _feeToken, uint _amount, uint _decimals) 
    OwnableByToken(_adminContract, _adminUid, _feeToken, _amount, _decimals) { }
    
//------------------------------------------------------------------------------------------------------------ MODIFIERS    
    modifier notBusy() { require(!busy, "ERROR: Please Try Again.");
        _; }
        
    modifier deployerOnly(uint auctionId, bool _bool) { 
        if(_bool) { require(msg.sender == auctionChain[auctionId].deployer, "msg.sender != auction.deployer"); }
        else { require(msg.sender != auctionChain[auctionId].deployer, "ERROR: msg.sender == auction.deployer"); }
        _; }
        
    modifier status(uint auctionId, uint _status, bool _bool) {
        if(_status == 0 && _bool == false) { require(auctionChain[auctionId].status != 0, "ERROR: Does Not Exist."); }
        if(_status == 1 && _bool == true) { require(auctionChain[auctionId].status == 1, "ERROR: Auction Not Active."); }
        if(_status == 2 && _bool == false) { require(auctionChain[auctionId].status != 2, "ERROR: Auction Not Active."); }
        if(_status == 3 && _bool == false) { require(auctionChain[auctionId].status != 3, "ERROR: Auction Not Active."); }
        if(_status == 4 && _bool == true) { require(auctionChain[auctionId].status == 4, "ERROR: Auction Already Activated"); }
        _; }

    /**@dev Allows execution while instance is active */
    modifier bidding(uint auctionId, bool _open) { 
        if(_open) { require(block.timestamp < auctionChain[auctionId].timeClose, "ERROR: Auction == Closed"); }
        else { require(block.timestamp >= auctionChain[auctionId].timeClose, "ERROR: Auction == Active"); }
        _; }
    
//------------------------------------------------------------------------------------------------------------ FRONT-END FUNCTIONS
    /**
     * @dev Places a bid on the item.
     * @param auctionId The id of an existing auction
     * @param _bid amount of tokens to bid
     */
    function auctionBid(uint auctionId, uint _bid) public 
    notBusy feeAllowance status(auctionId, 0, false) status(auctionId, 1, true) bidding(auctionId, true) deployerOnly(auctionId, false) {
        Auction memory check = auctionChain[auctionId]; 
        uint x = auctionId;
        uint dec = 10 ** check.r_decimals;
        uint bid = _bid;
        if (check.isPrivate){
            bool isWhitelisted; 
            for (uint i; i < check.participants.length-1; i++){ if(msg.sender ==  check.participants[i]) { isWhitelisted = true; } }
            require(isWhitelisted, "ERROR: msg.sender != whitelisted");}
        require(_bid > check.highestBid && bid > check.openingBid, "ERROR: _bid <= highestBid OR openingBid.");
        require(check.highestBidder != msg.sender, "ERROR: msg.sender == highestBidder.");        
        require(ERC20(check.r_token).balanceOf(msg.sender) >= bid * dec
            && ERC20(check.r_token).allowance(msg.sender, address(this)) >= bid * dec, "ERROR: Low Balance/Allowance");
        busy = true;
        // Return Previous Bid
            Auction storage auction = auctionChain[x];
            ERC20 token = ERC20(auction.r_token);
            uint corrected = auction.highestBid * dec;
            if(auction.highestBid != 0) { 
                if(token.allowance(address(this), address(this)) < corrected) { 
                    token.approve(address(this), token.balanceOf(address(this))); }
                token.transferFrom(address(this), auction.highestBidder, corrected); 
                _updateBidderRecord(x, 0, auction.highestBidder); }
        // Process Current Bid
            corrected = bid * dec;
            token.transferFrom(msg.sender, address(this), corrected); 
            _charge(); 
        // Emit Update
            bool exists;
            for (uint i = 0; i < historyOf[msg.sender].bids.length; i++) {
                if (historyOf[msg.sender].bids[i][0] == x) { exists = true; } }
            if(!exists) { 
                historyOf[msg.sender].bids.push([x, 1]); }
            else { 
                _updateBidderRecord(x, 1, msg.sender); }
            auction.highestBidder = msg.sender;
            auction.highestBid = bid;
        busy = false;
            emit Broadcast("Auction Updated ||", x, " Highest Bid Increased ||", auction.highestBidder, auction.highestBid); }

    /**
     * @dev Finalizes the auction and delivers the assets
     * @param auctionId The id of an existing auction
     */
    function auctionFinalize(uint auctionId) public 
    notBusy feeAllowance status(auctionId, 0, false) status(auctionId, 1, true) bidding(auctionId, false) { 
        require(auctionChain[auctionId].highestBidder != address(0), "No Highest Bidder");
        busy = true;
        Auction storage auction = auctionChain[auctionId];
            ERC20 rToken = ERC20(auction.r_token);
            _deliver(auction, auction.highestBidder);
            if(rToken.allowance(address(this), address(this)) < auction.highestBid * 10 ** auction.r_decimals) { 
                    rToken.approve(address(this), rToken.balanceOf(address(this))); }
            rToken.transferFrom(address(this), auction.deployer, auction.highestBid * 10 ** auction.r_decimals);
        // Emit Update
            _updateBidderRecord(auctionId, 2, auction.highestBidder);
            _updateDeployerRecord(auction, auctionId, 2);
            auctionChain[auctionId].status = 2; 
        busy = false;
             emit Broadcast("Auction Finalized ||", auctionId); } 

    /**
     * @dev Opens a new auction. Puts _token item in temporary escrow.
     * @param _yourAsset The contract address of ERC20 or ERC721 to put into auction.
     * @param _yourInt The id or amount of auctioned token.
     * @param _requestedToken the currency for bidding
     * @param _classification Type of asset. "TOKEN", "NFT"
     */
    function auctionInitialize(address _yourAsset, uint _yourInt, uint _yourDecimals, address _requestedToken, uint _requestedDecimals, string memory _classification) public 
    notBusy {
        require(_yourAsset != address(0) && _requestedToken != address(0), "ERROR: tokenAddress(es) == address(0)");
        require(_compareStrings(_classification,"TOKEN") || _compareStrings(_classification, "NFT"), "ERROR: classification != 20 || 721");
        if (_compareStrings(_classification, "NFT")) { 
            require(ERC721(_yourAsset).ownerOf(_yourInt) == msg.sender, "ERROR: ownerOf(token) != msg.sender"); }
        else { require(ERC20(_yourAsset).balanceOf(msg.sender) >= _yourInt * 10 ** _yourDecimals 
            && ERC20(_yourAsset).allowance(msg.sender, address(this)) >= _yourInt * 10 ** _yourDecimals, "ERROR: Low Balance/Allowance"); }
        // Process Deposit & Request Metadata
        if(_compareStrings(_classification, "NFT")) {
            require(ERC721(_yourAsset).getApproved(_yourInt) == address(this), "ERROR: Missing Approval for _yourAsset"); 
            ERC721(_yourAsset).transferFrom(msg.sender, address(this), _yourInt); }
        else{
            ERC20 dToken = ERC20(_yourAsset);
            require(_requestedToken != _yourAsset, "_yourAsset == _requestedToken");
            require(_yourInt != 0  && _yourDecimals != 0, "ERROR: Int/Decimals == 0.");
            require(dToken.allowance(msg.sender, address(this)) >= _yourInt * 10 ** _yourDecimals, "ERROR: Missing Approval for _yourAsset"); 
            dToken.transferFrom(msg.sender, address(this), _yourInt * 10 ** _yourDecimals); }
        busy = true;
        // Add to Pseudochain
            Auction storage newAuction = auctionChain[chainLength]; 
            newAuction.deployer = msg.sender;
            newAuction.classification = _classification;
            newAuction.d_token = _yourAsset;
            newAuction.d_int = _yourInt;
            newAuction.d_decimals = _yourDecimals;
            newAuction.r_token = _requestedToken;
            newAuction.r_decimals = _requestedDecimals;
            newAuction.status = 4;
            historyOf[msg.sender].deployed.push([chainLength, 4]);
            chainLength ++; 
        busy = false;
            emit Broadcast("Auction Initialized ||", chainLength-1); }

    /**
     * @dev Begins the Auction
     * @param auctionId The auction contract to start.
     * @param _length Length of time for the auction to be active (in seconds)
     * @param _openingBid Minimum opening bid
     * @param _whitelistedOnly true = turn on whitelist || false = do nothing
     * @param _whitelist array of whitelisted addresses [address, address, address, ...]
     */
    function auctionActivate(uint auctionId, uint _length, uint _openingBid, bool _whitelistedOnly, address[] calldata _whitelist) public 
    notBusy feeAllowance status(auctionId, 0, false) status(auctionId, 4, true) deployerOnly(auctionId, true) {
        require(_length >= 3600, "ERROR: length < 3600 Seconds (1 Hour)");
        uint x = auctionId;
        if(_whitelistedOnly) {  
            require(_whitelist[0] != address(0) && _whitelist[1] != address(0), "ERROR: whitelist.length < 2 "); 
            auctionChain[x].isPrivate = true; 
            for (uint i; i < _whitelist.length; i++){
                auctionChain[x].participants[i] = _whitelist[i]; } }
        busy = true; 
            Auction storage auction = auctionChain[x];
        // Emit Update
            _charge();
            auction.openingBid = _openingBid;
            auction.timeOpen = block.timestamp;
            auction.timeClose = block.timestamp + _length;
            auction.status = 1;
            _updateDeployerRecord(auction, x, 1);
        busy = false;
            emit Broadcast("Auction Activated ||", x, " Began:", auction.timeOpen, " Ends:", auction.timeClose); }
    
    /**
     * @dev Closes an auction before first bid. Retrieves _token item from auction.
     * @param auctionId The auction contract to close or abort.
     */
    function auctionAbort(uint auctionId) public 
    notBusy status(auctionId, 0, false) status(auctionId, 3, false) status(auctionId, 2, false) deployerOnly(auctionId, true) { 
        require(auctionChain[auctionId].highestBidder == address(0), "ERROR: highestBidder != address(0)");
        busy = true;
        // Return to Sender
            Auction storage auction = auctionChain[auctionId];
            _deliver(auction, auction.deployer);
        // Emit Update
            auction.status = 3; 
            _updateDeployerRecord(auction, auctionId, 3);
        busy = false;
                emit Broadcast("Auction Cancelled ||", auctionId); }

    
    /**
     * @dev Returns Auction Details || Machine Readable
     */
    function _viewAuction(uint auctionId) public status(auctionId, 0, false) view returns (Auction memory){ return (auctionChain[auctionId]); }
    
//------------------------------------------------------------------------------------------------------------ INTERNAL FUNCTIONS  
    function _deliver(Auction storage auction, address _address) internal {
        if(_compareStrings(auction.classification,"NFT")) { 
            ERC721(auction.d_token).transferFrom(address(this), _address, auction.d_int); }
        else { 
            ERC20 dToken = ERC20(auction.d_token);
            if(dToken.allowance(address(this), address(this)) < auction.d_int * 10 ** auction.d_decimals) { 
                dToken.approve(address(this), dToken.balanceOf(address(this))); }
            dToken.transferFrom(address(this), _address, auction.d_int * 10 ** auction.d_decimals); } } }