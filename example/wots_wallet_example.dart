import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';

void main() {
  print('WOTS Wallet Example\n');

  // Create a secret (32 bytes)
  final secret = Uint8List(32)..fillRange(0, 32, 0x56);
  final tag = Uint8List(12)..fillRange(0, 12, 0x34);
  
  print('Creating wallet with:');
  print('Secret (first 8 bytes): ${ByteUtils.bytesToHex(secret.sublist(0, 8))}...');
  print('Tag: ${ByteUtils.bytesToHex(tag)}');
  
  // Create the wallet
  final wallet = WOTSWallet(
    name: "Test Wallet",
    secret: secret,
    addrTag: tag
  );
  print('\nWallet created successfully!');

  // Get the public key (2208 bytes)
  final address = wallet.getAddress();
  if (address == null) {
    print('Error: Could not generate wallet address');
    return;
  }

  print('\nWallet information:');
  print('Name: ${wallet.getName()}');
  print('Address (first 32 bytes): ${ByteUtils.bytesToHex(address.sublist(0, 32))}...');
  
  final wotsHex = wallet.getWotsHex();
  if (wotsHex != null) {
    print('WOTS Hex (first 32 bytes): ${wotsHex.substring(0, 64)}...');
  }
  
  final tagHex = wallet.getAddrTagHex();
  if (tagHex != null) {
    print('Tag Hex: $tagHex');
  }

  // Demonstrate address validation
  print('\nValidating address...');
  final isValid = WOTS.isValid(secret, address);
  print('Address is ${isValid ? 'valid ✓' : 'invalid ✗'}');

  // Show tag extraction
  final extractedTag = wallet.getWotsTag();
  if (extractedTag != null) {
    print('\nExtracted tag matches original: ${ByteUtils.areEqual(tag, extractedTag) ? 'Yes ✓' : 'No ✗'}');
  } else {
    print('\nCould not extract tag from wallet');
  }
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