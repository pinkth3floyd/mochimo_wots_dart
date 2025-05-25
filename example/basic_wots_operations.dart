import 'dart:typed_data';
import 'package:mochimo_wots/core/protocol/tags.dart';
import 'package:mochimo_wots/core/protocol/wots.dart';

void main() {
  // Generate a valid WOTS address
  final sourcePK = Uint8List(2144);
  final sourceSecret = Uint8List(32)..fillRange(0, 32, 0x56); // Example secret
  final sourcePubSeed = Uint8List(32)
    ..fillRange(0, 32, 0x12); // Deterministic seed
  final sourceRnd2 = Uint8List(32)..fillRange(0, 32, 0x34);

  print('Generating WOTS public key...');
  WOTS.wotsPkgen(sourcePK, sourceSecret, sourcePubSeed, 0, sourceRnd2);
  print('Public key generated successfully!');

  // Create full address
  final sourceAddress = Uint8List(2208);
  sourceAddress.setRange(0, 2144, sourcePK);
  sourceAddress.setRange(2144, 2176, sourcePubSeed);
  sourceAddress.setRange(2176, 2208, sourceRnd2);

  print('\nCreated full address with components:');
  print(
      '- Public Key (first 32 bytes): ${_bytesToHex(sourcePK.sublist(0, 32))}...');
  print('- Public Seed: ${_bytesToHex(sourcePubSeed)}');
  print('- Random Seed: ${_bytesToHex(sourceRnd2)}');

  // Tag the address
  final tagBytes = Uint8List(12)..fillRange(0, 12, 0x12);
  final taggedSourceAddr = Tag.tag(sourceAddress, tagBytes);

  print('\nTagged address with tag: ${_bytesToHex(tagBytes)}');
  print(
      'Tagged address (first 32 bytes): ${_bytesToHex(taggedSourceAddr.sublist(0, 32))}...');
}

// Helper function to convert bytes to hex string
String _bytesToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
