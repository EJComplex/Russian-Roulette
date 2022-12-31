// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RussianRoulette {
    //constructor?
    // User must approve this contract
    // User calls pull to send tokens (amount). Transfer tokens to contract
    // call chainlink vrf. %6 or other method to determine 1-6.
    // if 6 burn tokens
    // if not 6 transfer tokens back to user
    // Considerations? make function that burns/calls vrf internal/private
    // If accepting any token, could a malicious token break contract?
    // add events

    

    

    function pull(uint256 tokenAmount, address tokenAddress) external {
        //user must approve this contract
        // msg.sender limits the token transfer from being called by non onwer addresses, even if approved.
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);

    }







}