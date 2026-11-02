# Mochimo WOTS Examples

This directory contains example code demonstrating various features of the Mochimo WOTS package.

## Examples Overview

1. `basic_wots_operations.dart` - Demonstrates basic WOTS operations including address generation and tagging
2. `advanced_wots_usage.dart` - Shows advanced usage with custom component generation using MochimoHasher
3. `byte_buffer_operations.dart` - Examples of using the ByteBuffer class and ByteUtils for binary data manipulation
4. `wots_wallet_example.dart` - Complete example of wallet creation and management with proper error handling
5. `signing_and_verifying.dart` - Demonstrates message signing and signature verification with error handling
6. `datagram_example.dart` - Builds a balance query in the version-4 PDU
7. `spend_example.dart` - Signs a transaction entry and wraps it in that PDU

## Running the Examples

To run any example, make sure you have the Mochimo WOTS package properly installed in your project. Then use the following command:

```bash
dart run example/<example_file>.dart
```

For instance, to run the basic WOTS operations example:

```bash
dart run example/basic_wots_operations.dart
```

## Example Descriptions

### Basic WOTS Operations
Demonstrates the fundamental operations of WOTS including:
- Generating a 2144-byte public key and the 2208-byte WOTS address
- Stamping the published 12-byte suffix (`0x42`, `0x0e`, `0x01`)
- Deriving the 40-byte account address and its 20-byte Base58 tag
- Replacing the suffix with `Tag.tag`, which is separate from the account tag

### Advanced WOTS Usage
Shows more complex usage patterns including:
- Custom component generation using MochimoHasher
- Deterministic address generation with proper byte manipulation
- Address validation and hex conversion
- Proper error handling

### ByteBuffer Operations
Illustrates how to use the ByteBuffer class and ByteUtils for:
- Writing data in different byte orders (big-endian and little-endian)
- Reading data back with proper byte order handling
- Buffer position management
- Converting between bytes and hex strings
- Proper error handling for buffer operations

### WOTS Wallet Example
Complete wallet management example showing:
- `WOTSWallet.create` with a 32-byte secret and a 20-byte account tag
- The 40-byte account address, its Base58 tag, and the 2208-byte WOTS blob
- Validation with the derived signing seed from `getSecret()`

### Signing and Verifying
Comprehensive example of cryptographic operations:
- Message signing with proper UTF-8 encoding
- Signature verification with error handling
- Handling modified messages
- Demonstrating signature tampering detection
- Using ByteUtils for hex conversion
- Proper exception handling

### Datagram
Builds a balance request on the current frame:
- Version 4, network id `0x3905`, trailer `0xCDAB`
- Opcode `OP_BALANCE` and a 40-byte account address

### Spend
Signs a node transaction:
- One or more 44-byte destinations, sorted the way `mdst_val` requires
- A change address that keeps the source account tag and uses the next key
- A 2208-byte WOTS value whose address seed ends in `420000000e00000001000000`
- The signed bytes are the header and destinations, hashed with SHA-256

## Notes

- All examples include proper error handling and null checking
- ByteUtils is used consistently for byte manipulation and hex conversion
- Examples demonstrate proper byte order handling where relevant
- All examples include detailed console output
- Helper functions are properly documented
- Examples use deterministic values for reproducibility
- A 12-byte `Tag` is the WOTS blob suffix. A 20-byte account tag is the ledger tag 