# Mochimo WOTS Examples

This directory contains example code demonstrating various features of the Mochimo WOTS package.

## Examples Overview

1. `basic_wots_operations.dart` - Demonstrates basic WOTS operations including address generation and tagging
2. `advanced_wots_usage.dart` - Shows advanced usage with custom component generation using MochimoHasher
3. `byte_buffer_operations.dart` - Examples of using the ByteBuffer class and ByteUtils for binary data manipulation
4. `wots_wallet_example.dart` - Complete example of wallet creation and management with proper error handling
5. `signing_and_verifying.dart` - Demonstrates message signing and signature verification with error handling

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
- Generating a WOTS public key
- Creating a full address
- Tagging an address
- Using ByteUtils for hex conversion

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
- Proper wallet creation with named parameters
- Safe address generation with null checking
- Tag management and validation
- Using ByteUtils for data conversion
- Proper error handling throughout

### Signing and Verifying
Comprehensive example of cryptographic operations:
- Message signing with proper UTF-8 encoding
- Signature verification with error handling
- Handling modified messages
- Demonstrating signature tampering detection
- Using ByteUtils for hex conversion
- Proper exception handling

## Notes

- All examples include proper error handling and null checking
- ByteUtils is used consistently for byte manipulation and hex conversion
- Examples demonstrate proper byte order handling where relevant
- All examples include detailed console output
- Helper functions are properly documented
- Examples use deterministic values for reproducibility 