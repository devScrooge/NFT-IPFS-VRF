// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol"; // to work with COORDINATOR and VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; // to use functionalities for Chainlink VRF

contract RandomIpfsNft is ERC721URIStorage, VRFConsumerBaseV2 { // To inherit functions

    VRFCoordinatorV2Interface immutable i_vrfCoordinator; // coordinator for working with Chainlink VRF 
    //|| i_ indicate inmutable variable (require low gas)

    bytes32 immutable i_gasLane;
    uint64 immutable i_subscriptionId;
    uint32 immutable callbackGasLimit;

    uint16 constant REQUEST_CONFIRMATIONS = 3; // how many blocks are needed to be considered complete
    uint32 constant NUM_WORDS = 1; // how many random numbers we want to get
    uint256 constant MAX_CHANCE_VALUE = 100; 

    mapping(uint256 => address) s_requestIdToSender;

    uint256 s_tokenCounter;

    /**
    * @dev 
    * - We are going to use VRFrequestRandomWords() function from Chainlink VRF
    * so we need to define each parameter that function uses in our contract constructor
    */
    constructor(address vrfCoordinatorV2, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) ERC721("Random IPFS NFT", "RIN") VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoodinatorV2Interface(vrfCoordinatorV2); // interface(address) -> contract, so i_vrfCoordinator is now a contract (we can interat with it)
        i_gasLane = gasLane; // keyHash -> how much gas is max to get Random Number (price per gas)
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit; // when Chainlink node respond with the random number it uses gas - max gas amount
        s_tokenCounter = 0;
    }

    /// @notice Mint a random puppy (get random number) -> use Chainlink VRF -> call requestRandomWords() function
    function requestDoggie() public returns (uint256 requestId){
        requestId = i_vrfCoordinator.requestRandomWords(i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS);

        s_requestIdToSender[requestId] = msg.sender; // get the address of the user that call requestDoggie function
    }

    /**
    * @dev 
    * - We are using _safeMint() function from OpenZeppelin
    */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) interal override {
        // owner of the dog
        address dogOwner = s_requestIdToSender[requestId];

        // asign this NFT a tokenId || update NFT id
        uint256 newTokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1; 

        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE; // apply modular operation to avoid having numbers like: 4869259398298299
        uint256 breed = getBreedFromModdedRng(moddedRng); // now we HAVE BREED

        // mint NFT
        _safeMint(dogOwner, newTokenId);

        // set tokenURI
        
    }
    
    
    /**
    * @notice Function to decide puppy breed randomly
    * @dev 
    * - 0-9: st.bernard
    * - 10-29: pug
    * - 30 - 99: shiba 
    */
    function getChanceArray() public pure returns(uint256[3] memory) {
        return [10, 30, MAX_CHANCE_VALUE];
    }

    function getBreedFromModdedRng(uint256 moddedRng) public pure returns (uint256) {
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        
        for (uint256 i=0; i < chanceArray.length; i++){
            if (moddedRng > cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]){
                // 0 = St.Bernard
                // 1 = Pug
                // 2 = Shiba
                return i;
            }
            cumulativeSum = cumulativeSum + chanceArray[i];
        }
    }

}