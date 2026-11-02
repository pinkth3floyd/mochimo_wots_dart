import 'dart:typed_data';
import 'dart:convert';
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  print('WOTS Signing and Verification Example\n');

  // Create a wallet for signing
  final secret = Uint8List(32)..fillRange(0, 32, 0x56);
  final tag = Uint8List(WotsAddress.ADDR_TAG_LEN)..fillRange(0, 20, 0x34);

  final wallet = WOTSWallet.create('Test Wallet', secret, tag);
  final address = wallet.getAddress();
  if (address == null) {
    print('Wallet is missing an account address');
    return;
  }

  print('Account address (40 bytes): ${ByteUtils.bytesToHex(address)}');
  print('Base58 tag: ${wallet.getAddrTagBase58()}\n');

  // A message that is not 32 bytes is SHA-256 hashed before it is signed.
  final message = 'Hello, Mochimo!';
  final messageBytes = Uint8List.fromList(utf8.encode(message));
  print('Original message: "$message"');
  print('Message bytes: ${ByteUtils.bytesToHex(messageBytes)}\n');

  try {
    // Sign the message
    print('Signing message...');
    final signature = wallet.sign(messageBytes);
    print(
        'Signature created (first 32 bytes): ${ByteUtils.bytesToHex(signature.sublist(0, 32))}...\n');

    // Verify the signature
    print('Verifying original message...');
    final isValid = wallet.verify(messageBytes, signature);
    print(
        'Signature verification result: ${isValid ? 'Valid ✓' : 'Invalid ✗'}\n');

    // Try to verify with a modified message
    final modifiedMessage = "Hello, Modified!";
    final modifiedBytes = Uint8List.fromList(utf8.encode(modifiedMessage));
    print('Verifying modified message: "$modifiedMessage"');
    final isValidModified = wallet.verify(modifiedBytes, signature);
    print(
        'Modified message verification result: ${isValidModified ? 'Valid' : 'Invalid ✗'} (expected: Invalid)');

    // Demonstrate signature tampering
    print('\nDemonstrating signature tampering:');
    final tamperedSignature = Uint8List.fromList(signature);
    tamperedSignature[0] ^= 1; // Flip one bit in the signature
    print('Verifying with tampered signature...');
    final isValidTampered = wallet.verify(messageBytes, tamperedSignature);
    print(
        'Tampered signature verification result: ${isValidTampered ? 'Valid' : 'Invalid ✗'} (expected: Invalid)');
  } catch (e) {
    print('Error during signing/verification: $e');
  }
}
