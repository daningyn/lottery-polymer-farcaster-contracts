//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import './base/CustomChanIbcApp.sol';

contract XLottery is CustomChanIbcApp {
    // application specific state
    uint64 public counter = 0; // challenge counter
    uint private nthGame = 0;
    uint private numOfChallenges;
    bool private isGameStarted;
    uint private challengeDuration;
    mapping(address => mapping(uint => mapping(uint => bool))) private checkLotteryMap;
    mapping(address => mapping(uint => mapping(uint => uint))) private lastUpdatedMap;
    mapping(address => mapping(uint => mapping(uint => uint))) private numberChoiceMap;

    constructor(IbcDispatcher _dispatcher) CustomChanIbcApp(_dispatcher) {}

    // application specific logic
    function resetCounter() internal {
        counter = 0;
    }

    function increment() internal {
        counter++;
    }

    function startNewGame(uint _numOfChallenge, uint _challengeDuration) external onlyOwner {
        require(isGameStarted != true, "Game is on.");
        numOfChallenges = _numOfChallenge;
        isGameStarted = true;
        challengeDuration = _challengeDuration;
        resetCounter();
        nthGame++;
    }

    function startNextChallenge() external onlyOwner {
        require(isGameStarted == true, "Game is not started.");
        require(counter < numOfChallenges, "No more challenge.");
        increment(); // increment challenge counter
    }

    // IBC logic

    /**
     * @dev Sends a packet with the caller address over a specified channel.
     * @param channelId The ID of the channel (locally) to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     */

    function sendPacket(
        bytes32 channelId,
        uint64 timeoutSeconds,
        uint _numberChoice
    ) external {
        numberChoiceMap[msg.sender][nthGame][counter] = _numberChoice;
        checkLotteryMap[msg.sender][nthGame][counter] = true;
        lastUpdatedMap[msg.sender][nthGame][counter] = block.timestamp;
        bytes memory payload = abi.encode(msg.sender, _numberChoice);

        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

        // calling the Dispatcher to send the packet
        dispatcher.sendPacket(channelId, payload, timeoutTimestamp);
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     * 
     * @param packet the IBC packet encoded by the source and relayed by the relayer.
     */
    function onRecvPacket(IbcPacket memory packet) external override onlyIbcDispatcher returns (AckPacket memory ackPacket) {
        require(isGameStarted == true, "Game is not started.");
        recvedPackets.push(packet);
        (address sender, uint _numberChoice) = abi.decode(packet.data, (address, uint));
        numberChoiceMap[sender][nthGame][counter] = _numberChoice;
        checkLotteryMap[sender][nthGame][counter] = true;
        lastUpdatedMap[sender][nthGame][counter] = block.timestamp;

        return AckPacket(true, abi.encode(numberChoiceMap[sender][nthGame][counter]));
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     * 
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onAcknowledgementPacket(IbcPacket calldata, AckPacket calldata ack) external override onlyIbcDispatcher {
        ackPackets.push(ack);
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     * 
     * @param packet the IBC packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutPacket(IbcPacket calldata packet) external override onlyIbcDispatcher {
        timeoutPackets.push(packet);
        // reset
        (address sender, uint _numberChoice) = abi.decode(packet.data, (address, uint));
        numberChoiceMap[sender][nthGame][counter] = 0;
        checkLotteryMap[sender][nthGame][counter] = false;
        lastUpdatedMap[sender][nthGame][counter] = 0;
    }

}
