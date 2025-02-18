// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Keccak256-Based PRNG
 * @notice A cryptographically secure PRNG based on Keccak-256
 * @dev Inspired by the C implementation, adapted for Solidity
 */
contract ZKNOX_keccak_prng {
    // State Variables
    bytes32 private state;
    uint64 private counter;
    bytes private buffer;
    bool private finalized;

    // Output buffer
    bytes32 private outBuffer;
    uint8 private outBufferPos;
    bool private outBufferValid;

    /**
     * @notice Initializes the PRNG state
     */
    constructor() {
        state = bytes32(0);
        counter = 0;
        buffer = "";
        finalized = false;
        outBufferPos = 0;
        outBufferValid = false;
    }

    /**
     * @notice Injects data into the PRNG state
     * @param input The data to inject
     */
    function inject(bytes memory input) public {
        require(!finalized, "Cannot inject after finalization");

        // Accumulate input into the buffer
        buffer = abi.encodePacked(buffer, input);
    }

    /**
     * @notice Finalizes the state for output generation
     */
    function flip() public {
        require(!finalized, "Already finalized");

        // Initialize state with the Keccak-256 of the buffer
        state = keccak256(buffer);
        finalized = true;

        // Reset output buffer
        outBufferPos = 0;
        outBufferValid = false;
    }

    /**
     * @notice Generates pseudorandom output
     * @param length The number of bytes to generate
     * @return randomBytes The generated pseudorandom bytes
     */
    function extract(uint256 length) public returns (bytes memory randomBytes) {
        require(finalized, "PRNG not finalized");

        randomBytes = new bytes(length);
        uint256 offset = 0;

        // Use any remaining bytes in the output buffer first
        while (outBufferValid && outBufferPos < 32 && offset < length) {
            randomBytes[offset] = outBuffer[outBufferPos];
            outBufferPos++;
            offset++;
        }

        // Generate additional blocks as needed
        while (offset < length) {
            // Prepare input block: state || counter (big-endian)
            bytes memory blockInput = abi.encodePacked(state, uint64ToBytes(counter));

            // Generate the next output block using Keccak-256
            outBuffer = keccak256(blockInput);
            outBufferPos = 0;
            outBufferValid = true;

            // Copy to output
            while (outBufferPos < 32 && offset < length) {
                randomBytes[offset] = outBuffer[outBufferPos];
                outBufferPos++;
                offset++;
            }

            // Increment the counter
            counter++;
        }
    }

    /**
     * @notice Helper function to convert uint64 to big-endian bytes
     * @param x The uint64 value to convert
     * @return b The big-endian bytes representation
     */
    function uint64ToBytes(uint64 x) internal pure returns (bytes memory b) {
        b = new bytes(8);
        for (uint256 i = 0; i < 8; i++) {
            b[i] = bytes1(uint8(x >> (56 - i * 8)));
        }
    }
}
