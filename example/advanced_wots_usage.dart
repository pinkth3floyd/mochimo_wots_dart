import 'dart:typed_data';
import 'package:mochimo_wots/core/protocol/wots.dart' show WOTS;
import 'package:mochimo_wots/mochimo_wots.dart';
import 'package:mochimo_wots/core/hasher/mochimo_hasher.dart';
import 'dart:convert';

// Custom components generator for deterministic addresses
Map<String, Uint8List> myComponentsGenerator(Uint8List seed) {
  // Create deterministic components using the seed
  final privateSeed = _generatePrivateSeed(seed);
  final publicSeed = _generatePublicSeed(seed);
  final addrSeed = _generateAddressSeed(seed);

  return {
    'private_seed': privateSeed,
    'public_seed': publicSeed,
    'addr_seed': addrSeed
  };
}

// Example implementation of private seed generation
Uint8List _generatePrivateSeed(Uint8List seed) {
  // Concatenate seed with 'private' string
  final input = Uint8List(seed.length + 7);
  input.setRange(0, seed.length, seed);
  input.setRange(seed.length, seed.length + 7, utf8.encode('private'));
  return MochimoHasher.hash(input);
}

// Example implementation of public seed generation
Uint8List _generatePublicSeed(Uint8List seed) {
  // Concatenate seed with 'public' string
  final input = Uint8List(seed.length + 6);
  input.setRange(0, seed.length, seed);
  input.setRange(seed.length, seed.length + 6, utf8.encode('public'));
  return MochimoHasher.hash(input);
}

// Example implementation of address seed generation
Uint8List _generateAddressSeed(Uint8List seed) {
  // Concatenate seed with 'address' string
  final input = Uint8List(seed.length + 7);
  input.setRange(0, seed.length, seed);
  input.setRange(seed.length, seed.length + 7, utf8.encode('address'));
  return MochimoHasher.hash(input);
}

void main() {
  // Create a secret seed
  final secret = Uint8List(32)..fillRange(0, 32, 0x12);
  final tag = Uint8List(12)..fillRange(0, 12, 0x34);

  print('Generating deterministic address...');
  print('Secret (hex): ${_bytesToHex(secret)}');
  print('Tag (hex): ${_bytesToHex(tag)}');

  // Generate deterministic address using custom components generator
  final address = WOTS.generateAddress(tag, secret, myComponentsGenerator);

  print('\nGenerated address components:');
  print('Address (first 32 bytes): ${_bytesToHex(address.sublist(0, 32))}...');

  // Validate address
  final isValid = WOTS.isValid(secret, address);
  print('\nAddress validation result: ${isValid ? 'Valid ✓' : 'Invalid ✗'}');

  // Example of how components are generated
  final components = myComponentsGenerator(secret);
  print('\nGenerated components:');
  print('Private Seed: ${_bytesToHex(components['private_seed']!)}');
  print('Public Seed: ${_bytesToHex(components['public_seed']!)}');
  print('Address Seed: ${_bytesToHex(components['addr_seed']!)}');
}

// Helper function to convert bytes to hex string
String _bytesToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
