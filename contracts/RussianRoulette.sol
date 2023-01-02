// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.7/VRFConsumerBase.sol";

contract RussianRoulette is VRFConsumerBase {
    //constructor?
    // User must approve this contract
    // User calls pull to send tokens (amount). Transfer tokens to contract
    // call chainlink vrf. %6 or other method to determine 1-6.
    // if 6 burn tokens
    // if not 6 transfer tokens back to user
    // Considerations? make function that burns/calls vrf internal/private
    // If accepting any token, could a malicious token break contract?
    // add events
    // set vrfcoordinator address to constant, change to router if needed
    // inherit vrfconsumerbase for now, keeping with examples
    // line 68 vrfconsumerbase security considerations
    // what to do if randomness is not found? send tokens back
    // fulfill randomness internal because only the inherited vrfconsumerbase can call it
    // fulfill randomness override becuase function is overwritten from inherited.
    // add payment necessary to pull, funding the link

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => address) public requestIdToToken;
    mapping(bytes32 => uint256) public requestIdToAmount;

    address public burnAddress = 0x0000000000000000000000000000000000000000;
    bytes32 public keyhash;
    uint256 public fee;
    event RequestRandomness(bytes32 requestId);
    event PostRandomNumber(uint256 randomness);

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyhash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyhash = _keyhash;
        fee = _fee;
    }
    

    

    function pull(uint256 tokenAmount, address tokenAddress) external {
        //user must approve this contract
        // msg.sender limits the token transfer from being called by non onwer addresses, even if approved.
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);

        bytes32 requestId = requestRandomness(keyhash, fee);
        requestIdToSender[requestId] = msg.sender;
        requestIdToToken[requestId] = tokenAddress;
        requestIdToAmount[requestId] = tokenAmount;
        emit RequestRandomness(requestId);


    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(_randomness > 0, "random-not-found");
        if (_randomness % 6 == 0) {
            IERC20(requestIdToToken[_requestId]).transfer(burnAddress, requestIdToAmount[_requestId]);
        } else {
            IERC20(requestIdToToken[_requestId]).transfer(requestIdToSender[_requestId], requestIdToAmount[_requestId]);
        }
        emit PostRandomNumber(_randomness);
    }







}