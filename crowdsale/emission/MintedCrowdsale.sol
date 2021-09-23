// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "../Crowdsale.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

// Syntax Update by CAT6#2699
/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */
abstract contract MintedCrowdsale is Crowdsale {

  ERC20PresetMinterPauser mintableToken = ERC20PresetMinterPauser(address(token));

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    override
    internal
  {
    ERC20PresetMinterPauser(mintableToken).mint(_beneficiary, _tokenAmount);
  }
}
