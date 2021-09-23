// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./OwnableByToken.sol";
import "./BoxOffice.sol";

/**
 * @dev adapted ERC721.sol for registering subseries of NFTs with included
 * seriesClerk permissions and management solution.
 * Author: CAT6#2699
 */
contract NFTicketFactory is ERC721, OwnableByToken  {
    using Strings for uint;
    
    event SeriesCreated(uint, string, string, string, string, string, address);
    event SeriesUpdated(uint, string, string);
    event SeriesUpdated(uint, string,  address);
    event TicketMinted(string, uint, string, uint, string, uint);
    event TicketPunched(string, uint, string, uint);

    string private _defaultBaseURI;
    
    uint private _seriesId;
    struct SeriesMetadata{ 
        string name;
        address boxOfficeAddress;
        bool boxOfficeState;
        string baseURI; 
        uint _ticketId; }
    mapping(uint => SeriesMetadata) private _series;
    
    uint private _tokenId;
    struct TokenMetadata {
        uint used;
        uint _seriesId;
        uint tickedId;
        uint ticketType; 
        address purchaser; } 
    mapping(uint => TokenMetadata) private _NFTicket;
    
    
    /**
    * @dev Sets the values for {adminTokenContract_} and {adminTokenId_}
    * These are immutable.
    */
    constructor() 
    ERC721("NFTickets by Cuneiform", "NFTX") {
        _defaultBaseURI = "http://localhost:9000/ticket/"; }

    /**
    * @dev allows access by the boxOffice, owner, or both
    */
    modifier onlyAdmin(uint seriesId, bool onlyBoxOffice, bool onlyActiveBoxOffice) { 
        require(seriesId != 0 && seriesId <= _seriesId, "ERROR: Out of Bounds");
        address seriesBoxOfficeAddress = viewSeries(seriesId).boxOfficeAddress;
        require(seriesBoxOfficeAddress == msg.sender || owner() == msg.sender, "ERROR: msg.sender != thisSeries.boxOfficeAddress/owner()");
        if(onlyBoxOffice) { 
            require(!BoxOffice(seriesBoxOfficeAddress).blocked(), "ERROR: msg.sender != BoxOffice Blocked");
            require(viewSeries(seriesId).boxOfficeAddress == msg.sender, "ERROR: msg.sender != thisSeries.boxOfficeAddress");
            if(onlyActiveBoxOffice) { require(viewSeries(seriesId).boxOfficeState, "ERROR: thisSeries.boxOfficeState Inactive"); } }
        else { require(!viewSeries(seriesId).boxOfficeState || BoxOffice(seriesBoxOfficeAddress).blocked(), "ERROR: thisSeries.boxOfficeState Active"); }
        _; }
        
    /**
    * @dev prevents erroneous boxOfficeAddress designation
    */
    modifier isBoxOfficeContract(address boxOfficeAddress) {
        require(BoxOffice(boxOfficeAddress).isBoxOfficeContract() || boxOfficeAddress == address(0), "ERROR: boxOfficeAddress is not a boxOffice");
        _; }
 
    /**
     * @dev pure and view functions
     */ 
    function isNFTicketFactoryContract() public pure returns (bool) { return true; }
    function compareStrings(string memory a, string memory b) public pure returns (bool) { return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))); }
    function fetchIndices() public view returns (uint, uint) { return (_seriesId, _tokenId); }
    function _baseURI() internal view override returns (string memory) { return _defaultBaseURI; } 
    
    function seriesMetadata(uint seriesId) public view returns (string memory, address, bool, string memory, uint) { return (viewSeries(seriesId).name, viewSeries(seriesId).boxOfficeAddress, viewSeries(seriesId).boxOfficeState, viewSeries(seriesId).baseURI, viewSeries(seriesId)._ticketId); }
    function viewSeries(uint seriesId) internal view returns (SeriesMetadata memory) { return _series[seriesId]; }
    function tokenMetadata(uint tokenId) public view returns (uint, uint, uint, uint, address) { return (viewToken(tokenId).used, viewToken(tokenId).tickedId, viewToken(tokenId)._seriesId, viewToken(tokenId).ticketType, viewToken(tokenId).purchaser); }
    function viewToken(uint tokenId) internal view returns (TokenMetadata memory) { return _NFTicket[tokenId]; }
    
    /**
    * @return resulting array is the user's current NFTicket collection
    */
    function userInventory(address user) 
    view public 
    returns (uint[] memory) {
        
        uint quantity = balanceOf(user);
        uint[] memory result = new uint[](quantity);
        
        if (quantity > 0) { 
            uint resultIndex = 0;
            for (uint currentIndex = 1; currentIndex <= _tokenId; currentIndex++) {
                if (ownerOf(currentIndex) == user) {
                    result[resultIndex] = currentIndex;
                    resultIndex++; } } }
                    
        return result; }
        
    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token with regard to thisTicketseriesId
     */  
    function tokenURI(uint tokenId) 
    public view virtual override 
    returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
        string memory baseURI = _baseURI();
        string memory assetURI = _series[_NFTicket[tokenId]._seriesId].baseURI;
        
        if(compareStrings(baseURI, assetURI)) { return string(abi.encodePacked(baseURI, tokenId.toString())); }
        else { return string(abi.encodePacked(assetURI, _NFTicket[tokenId].tickedId.toString())); } } 
            
    /**
    * @dev boxOffice function to mint new tokenId of 'ticketType' for '_seriesId' with '_ticketId' and transfers it to `recipient`.
    * NOTE: requires msg.sender == activeClerk for series
    * 
    * @param recipient Address to receive the newly minted 
    * @param seriesId Index of a specific series. 
    * _series[seriesId] represents the series designation for the new NFTicket @ _tokenId.
    * @param ticketType Denotes the nature of expiration for this ticket.
    * (e.g. 0 == Does Not Exist, 1 == View Once Only 'PPV', 2 == Unlimited Viewing for 3 Days "3DR", 3 == Unlimited Viewing Privileges "UVP")
    * 
    * @return Updated Indices
    */        
    function oc_issueTicket(address recipient, uint seriesId, uint ticketType) 
    public 
    onlyAdmin(seriesId, true, true)
    returns (uint, uint) { 
        
        _tokenId++;
        SeriesMetadata storage thisSeries = _series[seriesId]; 
        thisSeries._ticketId++;
        _mint(recipient, _tokenId);
        _NFTicket[_tokenId] = TokenMetadata(
            0,
            seriesId,
            thisSeries._ticketId,
            ticketType,
            recipient);
        emit TicketMinted("#", _tokenId, "| Asset:", seriesId, "| Type:", ticketType);
        
        return (_tokenId, thisSeries._ticketId); }
        
    /**
    * @dev boxOffice function to mark a tokenId as used
    * NOTE: requires msg.sender == activeClerk for series. UVP tokens may be repunched for infinite use.
    * 
    * @param seriesId Index of a specific series. _series[seriesId] represents the series object to be edited.
    * @param tokenId Index of a specific token. 
    * 
    */
    function oc_punchTicket(uint tokenId, uint seriesId) 
    public 
    onlyAdmin(seriesId, true, true)
    returns (uint) { 
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    require(viewToken(tokenId)._seriesId == seriesId, "ERROR: _seriesId Mismatch");
    if(viewToken(tokenId).ticketType != 3) { require(viewToken(tokenId).used == 0, "ERROR: Already Used"); }
    
        TokenMetadata storage thisToken = _NFTicket[tokenId];
        if(thisToken.ticketType != 3) { 
            _NFTicket[tokenId].used = block.timestamp; 
            emit TicketPunched("#", tokenId, " | Timestamp:", block.timestamp); }
            
        return block.timestamp; }
        
    /**
    * @dev boxOffice function to toggle boxOfficeState for a specific asset.  
    * NOTE: requires msg.sender == boxOfficeAddress for series. 
    * boxOfficeState must be true to allow ticket sales. 
    * This can also be used to migrate boxOffice privileges to a new contract.
    * 
    * @param seriesId Index of a specific series. _series[seriesId] represents the series object to be edited.
    * 
    * @return Current boxOfficeState for Series
    */    
    function oc_toggleState(uint seriesId) 
    public 
    onlyAdmin(seriesId, true, false)
    returns (bool) { 
        
        SeriesMetadata storage thisSeries = _series[seriesId];
        thisSeries.boxOfficeState = !thisSeries.boxOfficeState; 
        emit SeriesUpdated(seriesId, " boxOfficeState", "Toggled!");
        
        return thisSeries.boxOfficeState; }
        
    /**
    * @dev Owner/boxOffice function to update an asset after creation.
    * NOTE: requires msg.sender == boxOfficeAddress for series || owner() if boxOfficeAddress is not active
    * This is a precaution against misattributed series objects
    * (e.g. wrong boxOffice address, malfunctioning boxOffice contract, wrong name, wrong baseURI)
    * 
    * @param seriesId Index of a specific series. _series[seriesId] represents the series object to be edited.
    * @param boxOfficeAddress Address of the smart contract to receive authorization to dispense/punch tickets and update the asset.
    * (OPTIONAL) enter the zero address (e.g. address(0)) if you wish not to edit the boxOfficeAddress.
    * @param name String that designates the name of the series.
    * (OPTIONAL) enter an empty string (e.g. "") if you do not wish to edit the name
    * @param baseURI String that assigns a custom baseURI to the NFTicket series.
    * (OPTIONAL) enter an empty string (e.g. "") if you do not wish to edit the baseURI
    * 
    * @return Current Variable States for Series
    */
    function oa_updateAsset(uint seriesId, address boxOfficeAddress, string memory name, string memory baseURI) 
    public 
    onlyAdmin(seriesId, false, false) isBoxOfficeContract(boxOfficeAddress)
    returns (address, string memory, string memory) { 
    
        
        SeriesMetadata storage thisSeries = _series[seriesId];
        if(!compareStrings(thisSeries.name, name) && !compareStrings("", name)) { 
            thisSeries.name = name; 
            emit SeriesUpdated(seriesId, " | New Name:", name); }
        if(thisSeries.boxOfficeAddress != boxOfficeAddress && address(0) != boxOfficeAddress) { 
            thisSeries.boxOfficeAddress = boxOfficeAddress; 
            emit SeriesUpdated(seriesId, " | New boxOfficeAddress:", boxOfficeAddress);}
        if(!compareStrings(thisSeries.baseURI, baseURI) && !compareStrings("", baseURI)) { 
            thisSeries.baseURI = baseURI; 
            emit SeriesUpdated(seriesId, " | New baseURI:", baseURI);}  
            
            return (thisSeries.boxOfficeAddress, thisSeries.name, thisSeries.baseURI); }
            
    /**
    * @dev Owner funtion to register new series
    * 
    * @param boxOfficeAddress (OPTIONAL: Set to address(0)) Address of the smart contract to receive authorization to dispense/punch tickets and update the asset.
    * @param name (OPTIONAL: Set to "") String that designates the name of the series.
    * @param baseURI (OPTIONAL: Set to "") String that assigns a custom baseURI to the NFTicket series.
    */
    function oo_addAsset(string memory name, address boxOfficeAddress, string memory baseURI) 
    public 
    onlyOwner isBoxOfficeContract(boxOfficeAddress) { 
    
        _seriesId++;
        SeriesMetadata storage newSeries = _series[_seriesId];
        newSeries.name = name;
        newSeries.boxOfficeAddress = boxOfficeAddress;
        if(!compareStrings(name, "")) { newSeries.name = string(abi.encodePacked("Cuneiform Series:", _seriesId.toString())); } 
        else { newSeries.name = name; }
        if(!compareStrings(baseURI, "")) { newSeries.baseURI = baseURI; } 
        else { newSeries.baseURI = _baseURI(); }
            emit SeriesCreated(_seriesId, " | name:", name, "baseURI:", baseURI, " | boxOfficeAddress:", boxOfficeAddress); }
            
    /**
    * @dev Owner function to register new baseURI for migrations
    * 
    * @param baseURI new baseURI
    */
    function oo_defaultBaseURIUpdate(string memory baseURI) 
    public 
    onlyOwner { 
    require(!compareStrings(baseURI, "") || !compareStrings(baseURI, _defaultBaseURI), "ERROR: Invalid Input");
        _defaultBaseURI = baseURI; }
}