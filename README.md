## Deliverable 3: Explanation of Design Choices

### 🗺️ Grid and Movement Management

- The game operates on a **10x10 grid**, with each position uniquely identified by a number ranging from `0` to `99`.
- Player movement is restricted to adjacent positions (up, down, left, or right).
- The adjacency of positions is checked by comparing the row and column indices of the current and new positions.

### 💎 Treasure Movement

- **Initial Position**: The treasure's starting position is determined by hashing the block number at the time of contract deployment, ensuring an unpredictable starting point.
- **Dynamic Movement**:
  - **Multiple of 5**: If a player moves to a position that is a multiple of 5, the treasure moves to a random adjacent position.
  - **Prime Number**: If a player moves to a position that is a prime number, the treasure jumps to a completely new random position on the grid.
- **Randomness**: The randomness in treasure movement is derived from hashing the current timestamp using `block.timestamp`, ensuring unpredictability.

### 🔒 Security Considerations

- **Randomness Handling**: The contract uses the `keccak256` hash function, a common method in Solidity for generating pseudo-random values. While not perfectly secure (as miners could potentially influence the block timestamp), it is a reasonable compromise for this type of game considering the limitations of on-chain randomness.
- **Fair Play**: The contract includes checks to prevent multiple moves in the same turn, ensuring fairness among players.

### ⛽ Gas Optimization

- The `players` array tracks participants, allowing the `resetGame` function to efficiently clear the game state by iterating only over players who actually participated. This avoids the need to iterate over all possible addresses, which would be computationally expensive.
- The `isAdjacent` and `isPrime` functions are kept simple and pure, minimizing their gas consumption.
