// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;


import "@uniswapv3/contracts/libraries/TransferHelper.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract RussianRoulette is VRFV2WrapperConsumerBase {
    // add payment necessary to pull, funding the link

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    mapping(uint256 => address) public requestIdToSender;
    mapping(uint256 => address) public requestIdToToken;
    mapping(uint256 => uint256) public requestIdToAmount;
    // mapping(bytes32 => uint256) public requestIdToBlockNumber;
    // mapping(bytes32 => bool) public requestIdToRandomnessZero;

    address public burnAddress = address(0);
    // bytes32 public keyhash;
    // uint256 public fee;

    // event RequestRandomness(bytes32 requestId);

    // constructor(
    //     address _vrfCoordinator,
    //     address _link,
    //     bytes32 _keyhash,
    //     uint256 _fee
    // ) VRFConsumerBase(_vrfCoordinator, _link) {
    //     keyhash = _keyhash;
    //     fee = _fee;
    // }

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 10000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;

    //address linkAddress;
    //address wrapperAddress;

    constructor(address _linkAddress, address _wrapperAddress)
        VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
    {
        //linkAddress = _linkAddress;
        //wrapperAddress = _wrapperAddress;
    }
    

    
 
    function pull(uint256 _tokenAmount, address _tokenAddress) external returns (uint256 requestId){
        TransferHelper.safeTransferFrom(_tokenAddress, msg.sender, address(this), _tokenAmount);

        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        

        // bytes32 requestId = requestRandomness(keyhash, fee);
        requestIdToSender[requestId] = msg.sender;
        requestIdToToken[requestId] = _tokenAddress;
        requestIdToAmount[requestId] = _tokenAmount;
        // requestIdToBlockNumber[requestId] = block.number;
        // requestIdToRandomnessZero[requestId] = true;
        // emit RequestRandomness(requestId);
        return requestId;
        //return VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit);
    }

 
    // function returnToken(bytes32 _requestId) external {
    //     require((block.number - requestIdToBlockNumber[_requestId]) > 50 , "Too soon to assume failed randomness");
    //     require(requestIdToRandomnessZero[_requestId] == true, "Randomness was successful already");
    //     //IERC20(requestIdToToken[_requestId]).transfer(requestIdToSender[_requestId], requestIdToAmount[_requestId]);
    //     TransferHelper.safeTransfer(requestIdToToken[_requestId], requestIdToSender[_requestId], requestIdToAmount[_requestId]);
    //     requestIdToRandomnessZero[_requestId] = false;
    //     deleteMappings(_requestId);
    // }

    
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)
        internal
        override
    {
        require(s_requests[_requestId].paid > 0, "request not found");

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );

        if (_randomWords[0] % 6 == 0) {
            IERC20(requestIdToToken[_requestId]).transfer(burnAddress, requestIdToAmount[_requestId]);
            //requestIdToRandomnessZero[_requestId] = false;
            //deleteMappings(_requestId);
        } else {
            IERC20(requestIdToToken[_requestId]).transfer(requestIdToSender[_requestId], requestIdToAmount[_requestId]);
            //requestIdToRandomnessZero[_requestId] = false;
            //deleteMappings(_requestId);
        }
    }

    
    
    // function deleteMappings(bytes32 _requestId) private {
    //     // delete old mapping values
    //     delete requestIdToSender[_requestId];
    //     delete requestIdToToken[_requestId];
    //     delete requestIdToAmount[_requestId];
    //     delete requestIdToBlockNumber[_requestId];
    // }


}