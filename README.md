# Mochimo WOTS for Dart

A Dart implementation of the Mochimo WOTS (Winternitz One-Time Signature) protocol, providing cryptographic functionality for the Mochimo cryptocurrency network.

## Features

- WOTS signature generation and verification
- Address generation and management
- Network protocol implementation (Datagram)
- Utility functions for byte manipulation and CRC calculations

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

### Basic Usage

```dart
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  // Create a new WOTS wallet
  final wallet = WotsWallet();
  
  // Create a datagram
  final datagram = Datagram()
    ..setId1(1234)
    ..setId2(5678)
    ..setOperation(Operation.transaction);
    
  // Serialize datagram
  final bytes = datagram.serialize();
}
```

### Working with Datagrams

```dart
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  final datagram = Datagram();
  
  // Set transaction details
  datagram
    ..setOperation(Operation.transaction)
    ..setTotalSendBigInt(BigInt.from(1000000))
    ..setFeeBigInt(BigInt.from(1000));
    
  // Add capabilities
  datagram.setCapability(Capability.wallet, true);
  
  // Serialize and send
  final bytes = datagram.serialize();
}
```

