import 'dart:convert';
import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';

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
  // This 12-byte value is the WOTS address suffix, not the 20-byte account tag.
  final suffix = Uint8List(Tag.TAG_LENGTH)..fillRange(0, Tag.TAG_LENGTH, 0x34);

  print('Generating deterministic address...');
  print('Secret: ${ByteUtils.bytesToHex(secret)}');
  print('WOTS suffix: ${ByteUtils.bytesToHex(suffix)}');

  final address = WOTS.generateAddress(suffix, secret, myComponentsGenerator);
  final privateSeed = myComponentsGenerator(secret)['private_seed']!;
  final isValid = WOTS.isValid(privateSeed, address);

  final account =
      WotsAddress.wotsAddressFromBytes(address.sublist(0, WOTS.WOTSSIGBYTES));
  print('WOTS address valid: $isValid');
  print('WOTS suffix stored: ${ByteUtils.bytesToHex(address.sublist(2196))}');
  print('Implicit account: ${ByteUtils.bytesToHex(account.getAddress())}');
  print('Account tag: ${TagUtils.addrTagToBase58(account.getTag())}');

  final components = myComponentsGenerator(secret);
  print('Private seed: ${ByteUtils.bytesToHex(components['private_seed']!)}');
  print('Public seed: ${ByteUtils.bytesToHex(components['public_seed']!)}');
  print('Address seed: ${ByteUtils.bytesToHex(components['addr_seed']!)}');
}
