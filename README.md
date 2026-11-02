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
  mochimo_wots: ^2.0.0
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

void main() {
  final sourcePK = Uint8List(WOTS.WOTSSIGBYTES);
  final sourceSecret = Uint8List(32)..fillRange(0, 32, 0x56);
  final sourcePubSeed = Uint8List(32)..fillRange(0, 32, 0x12);
  final sourceRnd2 = Uint8List(32)..fillRange(0, 32, 0x34);

  WOTS.wotsPkgen(sourcePK, sourceSecret, sourcePubSeed, 0, sourceRnd2);

  // 2144-byte public key, 32-byte public seed, 32-byte address seed.
  final sourceAddress = Uint8List(2208);
  sourceAddress.setRange(0, WOTS.WOTSSIGBYTES, sourcePK);
  sourceAddress.setRange(WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32, sourcePubSeed);
  sourceAddress.setRange(2176, 2208, sourceRnd2);
  WOTS.stampAddressSuffix(sourceAddress);

  // 40-byte ledger address. Its tag is 20 bytes, not the 12-byte WOTS suffix.
  final account = WotsAddress.wotsAddressFromBytes(sourcePK);
  print(ByteUtils.bytesToHex(account.getAddress()));
  print(TagUtils.addrTagToBase58(account.getTag()));
}
```

### Advanced WOTS Usage

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';

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
  // 12-byte WOTS suffix. The account tag is a separate 20-byte value.
  final suffix = Uint8List(Tag.TAG_LENGTH)..fillRange(0, Tag.TAG_LENGTH, 0x34);

  final address = WOTS.generateAddress(suffix, secret, myComponentsGenerator);

  // Validate with the derived signing seed, not the original secret.
  final privateSeed = myComponentsGenerator(secret)['private_seed']!;
  final isValid = WOTS.isValid(privateSeed, address);
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
  buffer.order(ByteOrder.bigEndian).putInt(0x12345678);

  buffer.order(ByteOrder.littleEndian).putInt(0x9ABCDEF0);
  
  buffer.put(Uint8List.fromList([1, 2, 3, 4]));

  // Read data back
  buffer.rewind();
  buffer.order(ByteOrder.bigEndian);
  final int1 = _readIntFromBuffer(buffer, ByteOrder.bigEndian);

  buffer.order(ByteOrder.littleEndian);
  final int2 = _readIntFromBuffer(buffer, ByteOrder.littleEndian);
  
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
  
  if (order == ByteOrder.bigEndian) {
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

void main() {
  final secret = Uint8List(32)..fillRange(0, 32, 0x56);
  final tag = Uint8List(WotsAddress.ADDR_TAG_LEN)..fillRange(0, 20, 0x34);

  // tag is the 20-byte account tag. getAddress() returns the 40-byte account.
  final wallet = WOTSWallet.create('Test Wallet', secret, tag);
  print(ByteUtils.bytesToHex(wallet.getAddress()!));
  print(wallet.getAddrTagBase58());
}
```

### Signing and Verifying Messages

```dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  final secret = Uint8List(32)..fillRange(0, 32, 0x56);
  final tag = Uint8List(WotsAddress.ADDR_TAG_LEN)..fillRange(0, 20, 0x34);

  final wallet = WOTSWallet.create('Test Wallet', secret, tag);

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

### Datagram

```dart
import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  final account = Uint8List(40);
  final query = Datagram.balanceQuery(account);
  final parsed = Datagram.of(query.serialize());
  print(parsed.getVersion()); // 4
  print(parsed.getNetwork()); // 0x3905
  print(parsed.getOperation()); // Operation.balance
  print(parsed.getPayload().length); // 40
}
```

A spend is a separate payload: a 116-byte header, 44 bytes per destination, and a 2208-byte WOTS signature. `MochimoTransaction.sign` builds it, and `Datagram.setPayload` carries it under `Operation.transaction`. See `example/spend_example.dart`.

