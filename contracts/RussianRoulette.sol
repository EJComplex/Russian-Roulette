// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@chainlink/contracts/src/v0.7/VRFConsumerBase.sol";
import "@uniswapv3/contracts/libraries/TransferHelper.sol";

contract RussianRoulette is VRFConsumerBase {
    // add payment necessary to pull, funding the link

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => address) public requestIdToToken;
    mapping(bytes32 => uint256) public requestIdToAmount;
    mapping(bytes32 => uint256) public requestIdToBlockNumber;
    mapping(bytes32 => bool) public requestIdToRandomnessZero;

    address public burnAddress = address(0);
    bytes32 public keyhash;
    uint256 public fee;

    event RequestRandomness(bytes32 requestId);

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyhash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyhash = _keyhash;
        fee = _fee;
    }
    

    
    /**
     * @notice user must approve this contract for the token to be pulled
     * 
     * @dev pull transfers input token and input amount from msg.sender to contract
     * @dev requestRandomness is then called for chainlink vrfcoordinatorv1
     * @dev requestId is returned and mapped to the sender address, token address
     * @dev token amount, block number, and requestIdToRandomnessZero is set to true
     * @dev so if 50 blocks pass and randomness has failed to be provided the user can
     * @dev have their tokens returned.
     * 
     * @param _tokenAmount The quantity of token to be sent to Russian Roulette contract
     * @param _tokenAddress The address of the token to be sent to Russian Roulette contract
     */
    function pull(uint256 _tokenAmount, address _tokenAddress) external {
        TransferHelper.safeTransferFrom(_tokenAddress, msg.sender, address(this), _tokenAmount);

        bytes32 requestId = requestRandomness(keyhash, fee);
        requestIdToSender[requestId] = msg.sender;
        requestIdToToken[requestId] = _tokenAddress;
        requestIdToAmount[requestId] = _tokenAmount;
        requestIdToBlockNumber[requestId] = block.number;
        requestIdToRandomnessZero[requestId] = true;
        emit RequestRandomness(requestId);
    }

    /**
     * @dev Function returns user tokens if randomness is not found in 50 blocks
     * @dev More than 50 blocks must have passed since pull was called and the 
     * @dev requestIdToRandomnessZero mapping for the given requestId must be true.
     * @dev Tokens are transferred using uniswap library TransferHelper
     * @dev requestIdToRandomnessZero is set to false.
     * @dev deleteMappings is called to remove unecessary mappings
     * 
     * @param _requestId ID emitted from calling requestRandomness in pull function
     */
    function returnToken(bytes32 _requestId) external {
        require((block.number - requestIdToBlockNumber[_requestId]) > 50 , "Too soon to assume failed randomness");
        require(requestIdToRandomnessZero[_requestId] == true, "Randomness was successful already");
        //IERC20(requestIdToToken[_requestId]).transfer(requestIdToSender[_requestId], requestIdToAmount[_requestId]);
        TransferHelper.safeTransfer(requestIdToToken[_requestId], requestIdToSender[_requestId], requestIdToAmount[_requestId]);
        requestIdToRandomnessZero[_requestId] = false;
        deleteMappings(_requestId);
    }

    /**
     * @dev fulfillRandomness overwrites VRFConsumerBase.
     * @dev rawFulfillRandomness is called by the chainlink VRFCoordinator.
     * @dev _vrfCoordinator is set during construction, this limits the coordinator
     * @dev to be the only address able to call fulfillRandomness through rawFulfillRandomness.
     * @dev It is required that randomness be greater than 0.
     * @dev If randomness is divisible by 6, tokens are burned and mappings deleted
     * @dev If randomness is not divisible by 6, tokens are sent back to user and mappings are deleted
     * @dev In each case, requestIdToRandomnessZero is set to false since there is no need to recover tokens.
     * 
     * @param _requestId ID emitted from calling requestRandomness in pull function
     * @param _randomness Value returned by chainlink node, random uint256 number
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(_randomness > 0, "random-not-found");

        if (_randomness % 6 == 0) {
            IERC20(requestIdToToken[_requestId]).transfer(burnAddress, requestIdToAmount[_requestId]);
            requestIdToRandomnessZero[_requestId] = false;
            deleteMappings(_requestId);
        } else {
            IERC20(requestIdToToken[_requestId]).transfer(requestIdToSender[_requestId], requestIdToAmount[_requestId]);
            requestIdToRandomnessZero[_requestId] = false;
            deleteMappings(_requestId);
        }
    }

    
    /**
     * @dev private function called to delete unecessary mappings
     * 
     * @param _requestId ID emitted from calling requestRandomness in pull function
     */
    function deleteMappings(bytes32 _requestId) private {
        // delete old mapping values
        delete requestIdToSender[_requestId];
        delete requestIdToToken[_requestId];
        delete requestIdToAmount[_requestId];
        delete requestIdToBlockNumber[_requestId];
    }


}