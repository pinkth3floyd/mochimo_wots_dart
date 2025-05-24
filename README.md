# Mochimo WOTS for Dart

A Dart implementation of the Mochimo WOTS (Winternitz One-Time Signature) protocol, providing cryptographic functionality for the Mochimo cryptocurrency network.

## Features

- WOTS signature generation and verification
- Address generation and management
- Network protocol implementation (Datagram)
- Utility functions for byte manipulation and CRC calculations
- Tag-based address management
- Deterministic wallet generation

## Installation

Add this to your package's `pubspec.yaml` file:

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
import 'package:mochimo_wots/mochimo_wots.dart';

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
}
```

### Advanced WOTS Usage

```dart
import 'package:mochimo_wots/mochimo_wots.dart';

// Custom components generator for deterministic addresses
Map<String, Uint8List> myComponentsGenerator(Uint8List seed) {
  return {
    'private_seed': generatePrivateSeed(seed),
    'public_seed': generatePublicSeed(seed),
    'addr_seed': generateAddressSeed(seed)
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
}
```

### ByteBuffer Operations

```dart
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  // Create a new buffer
  final buffer = ByteBuffer.allocate(1024);

  // Write data
  buffer.order(ByteOrder.LITTLE_ENDIAN)
        .putInt(0x12345678)
        .put(Uint8List.fromList([1, 2, 3, 4]));

  // Read data
  final data = Uint8List(4);
  buffer.rewind().get(data);
}
```

### Creating a WOTS Wallet

```dart
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  // Create a secret (32 bytes)
  final secret = Uint8List(32)..fillRange(0, 32, 0x56);
  final tag = Uint8List(12)..fillRange(0, 12, 0x34);
  
  // Create the wallet
  final wallet = WOTSWallet.create("Test Wallet", secret, tag);

  // Get the public key (2208 bytes)
  final address = wallet.getAddress();
  print('Address: ${wallet.getWotsHex()}');

  // Get the tag
  print('Tag: ${wallet.getAddrTagHex()}');
}
```

### Signing and Verifying Messages

```dart
import 'package:mochimo_wots/mochimo_wots.dart';
import 'dart:convert';

void main() {
  final wallet = WOTSWallet.create("Test Wallet", secret, tag);

  // Message to sign
  final message = utf8.encode("Hello, Mochimo!");
  final messageBytes = Uint8List.fromList(message);

  // Sign the message
  final signature = wallet.sign(messageBytes);

  // Verify the signature
  final isValid = wallet.verify(messageBytes, signature);
  print('Signature valid: $isValid');

  // Verify with modified message (should fail)
  final modifiedMessage = utf8.encode("Hello, Modified!");
  final modifiedBytes = Uint8List.fromList(modifiedMessage);
  final isValidModified = wallet.verify(modifiedBytes, signature);
  print('Modified message valid: $isValidModified'); // false
}
```

