// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "../Crowdsale.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Syntax Update by CAT6#2699
/**
 * @title AllowanceCrowdsale
 * @dev Extension of Crowdsale where tokens are held by a wallet, which approves an allowance to the crowdsale.
 */
abstract contract AllowanceCrowdsale is Crowdsale {
  using SafeMath for uint256;

  address public tokenWallet;

  /**
   * @dev Constructor, takes token wallet address.
   * @param _tokenWallet Address holding the tokens, which has approved allowance to the crowdsale
   */
  constructor(address _tokenWallet) {
    require(_tokenWallet != address(0));
    tokenWallet = _tokenWallet;
  }

  /**
   * @dev Checks the amount of tokens left in the allowance.
   * @return Amount of tokens left in the allowance
   */
  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, address(this));
  }

  /**
   * @dev Overrides parent behavior by transferring tokens from wallet.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
  override
    internal
  {
    token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
  }
}
