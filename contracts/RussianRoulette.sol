// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

// IERC20 is already imported in TransferHelper.sol
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.7/VRFConsumerBase.sol";
import "@uniswapv3/contracts/libraries/TransferHelper.sol";

contract RussianRoulette is VRFConsumerBase {
    // User must approve this contract
    // User calls pull to send tokens (amount). Transfer tokens to contract
    // call chainlink vrf. %6 or other method to determine 1-6.
    // if 6 burn tokens
    // if not 6 transfer tokens back to user
    // line 68 vrfconsumerbase security considerations
    // what to do if randomness is not found? send tokens back
    // fulfill randomness internal because only the inherited vrfconsumerbase can call it
    // fulfill randomness override becuase function is overwritten from inherited.
    // add payment necessary to pull, funding the link

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => address) public requestIdToToken;
    mapping(bytes32 => uint256) public requestIdToAmount;
    mapping(bytes32 => uint256) public requestIdToBlockNumber;
    mapping(bytes32 => bool) public requestIdToRandomnessZero;

    address public burnAddress = 0x0000000000000000000000000000000000000000;
    bytes32 public keyhash;
    uint256 public fee;

    event RequestRandomness(bytes32 requestId);
    //event PostRandomNumber(uint256 randomness);

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyhash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyhash = _keyhash;
        fee = _fee;
    }
    

    

    function pull(uint256 _tokenAmount, address _tokenAddress) external {
        //user must approve this contract
        // msg.sender limits the token transfer from being called by non onwer addresses, even if approved.
        //IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        TransferHelper.safeTransferFrom(_tokenAddress, msg.sender, address(this), _tokenAmount);

        bytes32 requestId = requestRandomness(keyhash, fee);
        requestIdToSender[requestId] = msg.sender;
        requestIdToToken[requestId] = _tokenAddress;
        requestIdToAmount[requestId] = _tokenAmount;
        requestIdToBlockNumber[requestId] = block.number;
        requestIdToRandomnessZero[requestId] = true;
        emit RequestRandomness(requestId);


    }

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
        //emit PostRandomNumber(_randomness % 6);
    }

    function returnToken(bytes32 _requestId) external {
        require((block.number - requestIdToBlockNumber[_requestId]) > 50 , "Too soon to assume failed randomness");
        require(requestIdToRandomnessZero[_requestId] == true, "Randomness was successful already");
        IERC20(requestIdToToken[_requestId]).transfer(requestIdToSender[_requestId], requestIdToAmount[_requestId]);
        requestIdToRandomnessZero[_requestId] = false;
        deleteMappings(_requestId);

        

    }

    function deleteMappings(bytes32 _requestId) private {
        // delete old mapping values
        delete requestIdToSender[_requestId];
        delete requestIdToToken[_requestId];
        delete requestIdToAmount[_requestId];
        delete requestIdToBlockNumber[_requestId];
        //delete requestIdToRandomnessZero[_requestId];
    }







}