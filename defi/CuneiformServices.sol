// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./EscrowPseudochain.sol";
import "./ChargingForService.sol";

// Contract by CAT6#2699
contract CuneiformEscrow is EscrowPseudochain, ChargingForService {
    event PubliclyPrunable(bool);
    
    function _optional() internal virtual override { _chargeFee(); }
    
    bool private _publiclyPrunable;
    function isPubliclyPrunable() public view returns (bool) { return _publiclyPrunable; }
    
    function _callerRequirements(uint[] memory escrowArray) 
    internal virtual override view { 
        if(_publiclyPrunable) {
            for(uint i = 0; i < escrowArray.length; i++){ require(deployerOf(escrowArray[i]) == msg.sender, "ERROR: Caller not deployer of escrow(s)"); } }
        else { require(owner() == msg.sender, "ERROR: Caller not owner"); } }
        
    /*
     * @dev toggles the public ability to delete aborted escrows 
     *
     * @return current state
     */
    function oo_togglePublicPruning() public onlyOwner returns (bool) { 
        _publiclyPrunable = !_publiclyPrunable; 
        emit PubliclyPrunable(_publiclyPrunable);
        
        return _publiclyPrunable; }
}