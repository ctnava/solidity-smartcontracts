// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./Crowdsale.sol";
// Syntax Update by CAT6#2699
contract sampleCrowdsale is Crowdsale {
    
    constructor() Crowdsale(1000000, 0xEF25f303d9d13414839959c66335FF822F6e5e42, 0x756Bf2bA867506fc5f87a07D7EF164991B13c905) {
	//(uint256 _rate, address _wallet, address _token)
    }
}