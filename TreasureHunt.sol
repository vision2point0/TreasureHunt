// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasureHunt {
    uint8 constant GRID_SIZE = 10;
    uint8 constant TOTAL_GRID_CELLS = GRID_SIZE * GRID_SIZE;

    address public owner;
    address public winner;
    address[] private players;
    uint8 public treasurePosition;
    bool public gameEnded;

    mapping(address => uint8) public playerPositions;
    mapping(address => bool) public hasPlayed;

    event PlayerMoved(address indexed player, uint8 newPosition);
    event TreasureMoved(uint8 newTreasurePosition);
    event WinnerDeclared(address indexed winner, uint256 reward);

    constructor() {
        owner = msg.sender;
        treasurePosition = uint8(uint256(keccak256(abi.encodePacked(block.number))) % TOTAL_GRID_CELLS);
        gameEnded = false;
    }

    modifier onlyWhenGameActive() {
        require(!gameEnded, "The game has already ended.");
        _;
    }

    function move(uint8 newPosition) external payable onlyWhenGameActive {
        require(msg.value > 0, "You must send ETH to participate.");
        require(newPosition < TOTAL_GRID_CELLS, "Invalid position on the grid.");
        require(hasPlayed[msg.sender] == false, "You can only move once per turn.");

        if (playerPositions[msg.sender] == 0) {
            playerPositions[msg.sender] = newPosition;
            players.push(msg.sender); // Track players who have moved
        } else {
            uint8 currentPosition = playerPositions[msg.sender];
            require(isAdjacent(currentPosition, newPosition), "You can only move to adjacent positions.");
            playerPositions[msg.sender] = newPosition;
        }

        hasPlayed[msg.sender] = true;
        emit PlayerMoved(msg.sender, newPosition);

        // Check if the player found the treasure
        if (newPosition == treasurePosition) {
            declareWinner(msg.sender);
            return;
        }

        // Move the treasure based on game rules
        moveTreasure(newPosition);
    }

    function isAdjacent(uint8 fromPosition, uint8 toPosition) internal pure returns (bool) {
        uint8 row = fromPosition / GRID_SIZE;
        uint8 col = fromPosition % GRID_SIZE;

        uint8 targetRow = toPosition / GRID_SIZE;
        uint8 targetCol = toPosition % GRID_SIZE;

        return (row == targetRow && (col == targetCol + 1 || col == targetCol - 1)) ||
               (col == targetCol && (row == targetRow + 1 || row == targetRow - 1));
    }

    function moveTreasure(uint8 playerPosition) internal {
        bool moved = false;

        if (playerPosition % 5 == 0) {
            uint8[] memory adjacentPositions = getAdjacentPositions(treasurePosition);
            treasurePosition = adjacentPositions[uint256(keccak256(abi.encodePacked(block.timestamp))) % adjacentPositions.length];
            moved = true;
        }

        if (isPrime(playerPosition)) {
            treasurePosition = uint8(uint256(keccak256(abi.encodePacked(block.timestamp))) % TOTAL_GRID_CELLS);
            moved = true;
        }

        if (moved) {
            emit TreasureMoved(treasurePosition);
        }
    }

    function getAdjacentPositions(uint8 position) internal pure returns (uint8[] memory) {
    uint8 row = position / GRID_SIZE;
    uint8 col = position % GRID_SIZE;

    uint8[4] memory positions; // Declare an array to hold up to 4 possible adjacent positions
    uint8 count = 0;

    if (row > 0) positions[count++] = position - GRID_SIZE; // Up
    if (row < GRID_SIZE - 1) positions[count++] = position + GRID_SIZE; // Down
    if (col > 0) positions[count++] = position - 1; // Left
    if (col < GRID_SIZE - 1) positions[count++] = position + 1; // Right

    uint8[] memory adjacentPositions = new uint8[](count); // Create a new array of the correct size
    for (uint8 i = 0; i < count; i++) {
        adjacentPositions[i] = positions[i]; // Copy the positions to the final array
    }

    return adjacentPositions;
}


    function isPrime(uint8 number) internal pure returns (bool) {
        if (number < 2) return false;
        for (uint8 i = 2; i <= number / 2; i++) {
            if (number % i == 0) return false;
        }
        return true;
    }

    function declareWinner(address player) internal {
        winner = player;
        gameEnded = true;

        uint256 reward = address(this).balance * 90 / 100;
        payable(player).transfer(reward);
        emit WinnerDeclared(player, reward);
    }

    function resetGame() external {
        require(msg.sender == owner, "Only the owner can reset the game.");
        require(gameEnded, "The game is still active.");

        // Reset the hasPlayed mapping for all players who participated
        for (uint8 i = 0; i < players.length; i++) {
            hasPlayed[players[i]] = false;
            playerPositions[players[i]] = 0; // Optionally reset player positions
        }

        // Clear the players array for the next round
        delete players;

        // Reset the treasure position
        treasurePosition = uint8(uint256(keccak256(abi.encodePacked(block.number))) % TOTAL_GRID_CELLS);
        gameEnded = false;
        winner = address(0);
    }
}
