# Mochimo WOTS Examples

This directory contains example code demonstrating various features of the Mochimo WOTS package.

## Examples Overview

1. `basic_wots_operations.dart` - Demonstrates basic WOTS operations including address generation and tagging
2. `advanced_wots_usage.dart` - Shows advanced usage with custom component generation
3. `byte_buffer_operations.dart` - Examples of using the ByteBuffer class for binary data manipulation
4. `wots_wallet_example.dart` - Complete example of wallet creation and management
5. `signing_and_verifying.dart` - Demonstrates message signing and signature verification

## Running the Examples

To run any example, make sure you have the Mochimo WOTS package properly installed in your project. Then use the following command:

```bash
dart run examples/<example_file>.dart
```

For instance, to run the basic WOTS operations example:

```bash
dart run examples/basic_wots_operations.dart
```

## Example Descriptions

### Basic WOTS Operations
Demonstrates the fundamental operations of WOTS including:
- Generating a WOTS public key
- Creating a full address
- Tagging an address

### Advanced WOTS Usage
Shows more complex usage patterns including:
- Custom component generation
- Deterministic address generation
- Address validation

### ByteBuffer Operations
Illustrates how to use the ByteBuffer class for:
- Writing different data types
- Reading data back
- Buffer position management
- Using mark and reset functionality

### WOTS Wallet Example
Complete wallet management example showing:
- Wallet creation
- Address generation
- Tag management
- Address validation

### Signing and Verifying
Comprehensive example of cryptographic operations:
- Message signing
- Signature verification
- Handling modified messages
- Demonstrating signature tampering detection

## Notes

- All examples include detailed console output to help understand what's happening at each step
- The examples use deterministic values for reproducibility
- Error handling is included where appropriate
- Helper functions are provided for common operations like hex conversion 