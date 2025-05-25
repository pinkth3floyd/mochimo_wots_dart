# Mochimo WOTS for Dart

A Dart implementation of the [Mochimo](https://mochimo.org) WOTS (Winternitz One-Time Signature) protocol, providing cryptographic functionality for the Mochimo cryptocurrency network.

Thank You [Aatma(Anuj Wagle)](https://github.com/wagleanuj) for supporting. 
Inspired by TypeScript implementation of wots by Anuj [Repo](https://github.com/wagleanuj/mochimo-wots)

## Features

- WOTS signature generation and verification
- Address generation and management
- Network protocol implementation (Datagram)
- Utility functions for byte manipulation and CRC calculations
- Tag-based address management
- Deterministic wallet generation

## Installation

```yaml
dependencies:
  mochimo_wots: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Usage

### WOTS Operations

```dart
import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';

void main() {
  // Generate a valid WOTS address
  final sourcePK = Uint8List(2144);
  final sourcePubSeed = Uint8List(32)..fillRange(0, 32, 0x12); // Deterministic seed
  final sourceRnd2 = Uint8List(32)..fillRange(0, 32, 0x34);
  
  WOTS.wotsPkgen(sourcePK, sourceSecret, sourcePubSeed, 0, sourceRnd2);
  
  // Create full address
  final sourceAddress = Uint8List(2208);
  sourceAddress.setRange(0, 2144, sourcePK);
  sourceAddress.setRange(2144, 2176, sourcePubSeed);
  sourceAddress.setRange(2176, 2208, sourceRnd2);
  
  // Tag the address
  final tagBytes = Uint8List(12)..fillRange(0, 12, 0x12);
  final taggedSourceAddr = Tag.tag(sourceAddress, tagBytes);
  
  // Display the address
  print('Address: ${ByteUtils.bytesToHex(taggedSourceAddr)}');
}
```

### Advanced WOTS Usage

```dart
import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';
import 'package:mochimo_wots/core/hasher/mochimo_hasher.dart';

// Custom components generator for deterministic addresses
Map<String, Uint8List> myComponentsGenerator(Uint8List seed) {
  // Concatenate seed with identifiers and hash
  final privateSeedInput = Uint8List(seed.length + 7);
  privateSeedInput.setRange(0, seed.length, seed);
  privateSeedInput.setRange(seed.length, seed.length + 7, utf8.encode('private'));
  
  final publicSeedInput = Uint8List(seed.length + 6);
  publicSeedInput.setRange(0, seed.length, seed);
  publicSeedInput.setRange(seed.length, seed.length + 6, utf8.encode('public'));
  
  final addrSeedInput = Uint8List(seed.length + 7);
  addrSeedInput.setRange(0, seed.length, seed);
  addrSeedInput.setRange(seed.length, seed.length + 7, utf8.encode('address'));

  return {
    'private_seed': MochimoHasher.hash(privateSeedInput),
    'public_seed': MochimoHasher.hash(publicSeedInput),
    'addr_seed': MochimoHasher.hash(addrSeedInput)
  };
}

void main() {
  final secret = Uint8List(32)..fillRange(0, 32, 0x12);
  final tag = Uint8List(12)..fillRange(0, 12, 0x34);

  // Generate deterministic address
  final address = WOTS.generateAddress(tag, secret, myComponentsGenerator);

  // Validate address
  final isValid = WOTS.isValid(secret, address);
  print('Address valid: $isValid');
  print('Address: ${ByteUtils.bytesToHex(address)}');
}
```

### ByteBuffer Operations

```dart
import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';

void main() {
  // Create a new buffer
  final buffer = ByteBuffer.allocate(32);

  // Write data in different byte orders
  buffer.order(ByteOrder.BIG_ENDIAN)
        .putInt(0x12345678);
  
  buffer.order(ByteOrder.LITTLE_ENDIAN)
        .putInt(0x9ABCDEF0);
  
  buffer.put(Uint8List.fromList([1, 2, 3, 4]));

  // Read data back
  buffer.rewind();
  buffer.order(ByteOrder.BIG_ENDIAN);
  final int1 = _readIntFromBuffer(buffer, ByteOrder.BIG_ENDIAN);
  
  buffer.order(ByteOrder.LITTLE_ENDIAN);
  final int2 = _readIntFromBuffer(buffer, ByteOrder.LITTLE_ENDIAN);
  
  final bytes = Uint8List(4);
  buffer.get(bytes);
  
  print('Read values:');
  print('First int (BE): ${ByteUtils.toHexString(int1)}');
  print('Second int (LE): ${ByteUtils.toHexString(int2)}');
  print('Bytes: ${ByteUtils.bytesToHex(bytes)}');
}

int _readIntFromBuffer(ByteBuffer buffer, ByteOrder order) {
  final b1 = buffer.get_();
  final b2 = buffer.get_();
  final b3 = buffer.get_();
  final b4 = buffer.get_();
  
  if (order == ByteOrder.BIG_ENDIAN) {
    return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
  } else {
    return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
  }
}
```

### Creating a WOTS Wallet

```dart
import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';

void main() {
  // Create a secret (32 bytes)
  final secret = Uint8List(32)..fillRange(0, 32, 0x56);
  final tag = Uint8List(12)..fillRange(0, 12, 0x34);
  
  // Create the wallet
  final wallet = WOTSWallet(
    name: "Test Wallet",
    secret: secret,
    addrTag: tag
  );

  // Get the public key (2208 bytes)
  final address = wallet.getAddress();
  if (address == null) {
    print('Error: Could not generate wallet address');
    return;
  }

  print('Address: ${ByteUtils.bytesToHex(address)}');
  
  final tagHex = wallet.getAddrTagHex();
  if (tagHex != null) {
    print('Tag: $tagHex');
  }
}
```

### Signing and Verifying Messages

```dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:mochimo_wots/mochimo_wots.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';

void main() {
  final secret = Uint8List(32)..fillRange(0, 32, 0x56);
  final tag = Uint8List(12)..fillRange(0, 12, 0x34);
  
  final wallet = WOTSWallet(
    name: "Test Wallet",
    secret: secret,
    addrTag: tag
  );

  try {
    // Message to sign
    final message = "Hello, Mochimo!";
    final messageBytes = Uint8List.fromList(utf8.encode(message));

    // Sign the message
    final signature = wallet.sign(messageBytes);
    print('Signature: ${ByteUtils.bytesToHex(signature)}');

    // Verify the signature
    final isValid = wallet.verify(messageBytes, signature);
    print('Signature valid: $isValid');

    // Verify with modified message (should fail)
    final modifiedMessage = "Hello, Modified!";
    final modifiedBytes = Uint8List.fromList(utf8.encode(modifiedMessage));
    final isValidModified = wallet.verify(modifiedBytes, signature);
    print('Modified message valid: $isValidModified'); // false
  } catch (e) {
    print('Error during signing/verification: $e');
  }
}
```

