import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  print('WOTS Wallet Example\n');

  // Create a secret (32 bytes)
  final secret = Uint8List(32)..fillRange(0, 32, 0x56);
  final tag = Uint8List(12)..fillRange(0, 12, 0x34);
  
  print('Creating wallet with:');
  print('Secret (first 8 bytes): ${_bytesToHex(secret.sublist(0, 8))}...');
  print('Tag: ${_bytesToHex(tag)}');
  
  // Create the wallet
  final wallet = WOTSWallet.create("Test Wallet", secret, tag);
  print('\nWallet created successfully!');

  // Get the public key (2208 bytes)
  final address = wallet.getAddress();
  print('\nWallet information:');
  print('Name: ${wallet.name}');
  print('Address (first 32 bytes): ${_bytesToHex(address.sublist(0, 32))}...');
  print('WOTS Hex (first 32 bytes): ${wallet.getWotsHex().substring(0, 64)}...');
  print('Tag Hex: ${wallet.getAddrTagHex()}');

  // Demonstrate address validation
  print('\nValidating address...');
  final isValid = WOTS.isValid(secret, address);
  print('Address is ${isValid ? 'valid ✓' : 'invalid ✗'}');

  // Show tag extraction
  final extractedTag = wallet.getWotsTag();
  print('\nExtracted tag matches original: ${_compareBytes(tag, extractedTag) ? 'Yes ✓' : 'No ✗'}');
}

// Helper function to convert bytes to hex string
String _bytesToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

// Helper function to compare two Uint8List
bool _compareBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
} 