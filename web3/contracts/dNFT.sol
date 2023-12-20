// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

contract ArtistNFT is
    ERC721,
    ERC721URIStorage,
    VRFConsumerBaseV2,
    FunctionsClient
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //CHAINLINKFUNCTIONS
    using FunctionsRequest for FunctionsRequest.Request;
    string memory source;
    bytes32 public donId;
    bytes public s_lastResponse;
    bytes public s_lastError;
    string source;
    uint8 donHostedSecretsSlotId;
    uint64 donHostedSecretsversion;
    bytes[] bytesArgs;
    uint64 private f_subscriptionId;
    uint32 callbackGasLimit;
    mapping (uint256 => address) private f_requester;

    //VRF SETUP
    uint256[] public s_randomWords;
    uint64 private v_subscriptionId;
    address s_owner;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 s_keyHash;
    address vrfCoordinator;
    mapping (uint256 => address) private v_vrfRequester;
    mapping (address => uint256) private v_results;


    constructor(
        address f_router,
        string _source,
        bytes32 _donId,
        uint8 _donHostedSecretsSlotId,
        uint64 _donHostedSecretsversion,
        bytes[] memory _bytesArgs,
        uint64 _subscriptionId,
        uint64 _v_subscriptionId,
        bytes32 _s_keyHash,
        address _vrfCoordinator
    ) FunctionsClient(f_router), VRFConsumerBaseV2(_vrfCoordinator), 
    ERC721("dNFT", "DNFT") {
        source = _source;
        donId = _donId;
        donHostedSecretsSlotId = _donHostedSecretsSlotId;
        donHostedSecretsversion = _donHostedSecretsversion;
        bytesArgs = _bytesArgs;
        f_subscriptionId = _subscriptionId;
        callbackGasLimit = 3000000;
        v_subscriptionId = _v_subscriptionId;
        s_keyHash = _s_keyHash;
        vrfCoordinator = _vrfCoordinator;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;

    }

    function sendRequest(string memory args) public returns(uint256 requestId) {
        FunctionsRequest.Request memory req;
        req.setArgs(args);
        req.initializeRequestForInlineJavaScript(source);
        requestId = _sendRequest(
            req.encodeCBOR(),
            f_subscriptionId,
            callbackGasLimit,
            donId
        )
    }

    function getRandomWords() public returns(uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            v_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        v_vrfRequester[requestId] = msg.sender;
        v_results[]
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        s_lastResponse = response;
        s_lastError = err;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) public override onlyVRFCoordinator {
        s_randomWords = randomWords;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
