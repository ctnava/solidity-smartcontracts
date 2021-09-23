// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./TestTokenModules.sol";
/**
 * @dev A bunch of random test tokens
 * AUTHOR: CAT6#2699
 */
contract NFT0 is TestNFT { constructor(address contractAddress) FreelyMintableNFT("optionalURI", "Admin Token", "ADMIN") Debugger(contractAddress) { quickMint(); } } 
contract NFT00 is TestNFT { constructor(address contractAddress) FreelyMintableNFT("optionalURI", "Admin Override Token", "ADMIN+") Debugger(contractAddress) { quickMint(); } } 
contract NFT1 is TestNFT { constructor(address contractAddress) FreelyMintableNFT("optionalURI", 'Expensive JPEG', '$JPG') Debugger(contractAddress) {} }
contract NFT2 is TestNFT { constructor(address contractAddress) FreelyMintableNFT("optionalURI", 'Nifty Trash', 'TRASH') Debugger(contractAddress) {} }
contract NFT3 is TestNFT { constructor(address contractAddress) FreelyMintableNFT("optionalURI", 'Wrapped Fortnite Skins', '4SKINZ') Debugger(contractAddress) {} }
contract NFT4 is TestNFT { constructor(address contractAddress) FreelyMintableNFT("optionalURI", 'Dick Pics', 'DIX') Debugger(contractAddress) {} }
contract NFT5 is TestNFT { constructor(address contractAddress) FreelyMintableNFT("optionalURI", 'Most Definitely Not Money Laundry', 'DIRTY$') Debugger(contractAddress) {} }

contract Token0 is TestToken { constructor(address contractAddress) FreelyMintableToken('Fee Coin', 'FEE') Debugger(contractAddress) {} }
contract Token1 is TestToken { constructor(address contractAddress) FreelyMintableToken('Bless Up', 'COINYE') Debugger(contractAddress) {} }
contract Token2 is TestToken { constructor(address contractAddress) FreelyMintableToken('Not a Breast Cancer Charity Scam', 'BOOBUX') Debugger(contractAddress) {} }
contract Token3 is TestToken { constructor(address contractAddress) FreelyMintableToken('Probably a Pump and Dump', 'CHUMP') Debugger(contractAddress) {} }