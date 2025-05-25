import 'dart:typed_data';
import 'dart:math';
import 'package:mochimo_wots/core/model/byte_buffer.dart';
import 'package:mochimo_wots/core/protocol/wots_address.dart';
import 'package:mochimo_wots/core/protocol/wots_hash.dart';
import 'package:mochimo_wots/core/protocol/tags.dart';

typedef RandomGenerator = void Function(Uint8List bytes);

class WOTS {
  // WOTS parameters
  static const int WOTSW = 16;
  static const int WOTSLOGW = 4;
  static const int PARAMSN = 32;
  static const int WOTSLEN1 = 64;
  static const int WOTSLEN2 = 3;
  static const int WOTSLEN = 67;
  static const int WOTSSIGBYTES = 2144;
  static const int TXSIGLEN = 2144;

  /// Generates chains for WOTS
  static void genChain(
    Uint8List out,
    int outOffset,
    Uint8List input,
    int inOffset,
    int start,
    int steps,
    Uint8List pubSeed,
    Uint8List addr,
  ) {
    // Copy input to output
    out.setRange(outOffset, outOffset + PARAMSN, input, inOffset);

    // Create WotsAddress instance from addr bytes
    final wotsAddr = WotsAddress.wotsAddressFromBytes(addr);
    final bbaddr = ByteBuffer.wrap(wotsAddr.bytes().sublist(0, PARAMSN));
    bbaddr.order(ByteOrder.littleEndian);

    // Generate chain
    for (int i = start; i < start + steps && i < WOTSW; i++) {
      WOTSHash.setHashAddr(bbaddr, i);
      WOTSHash.thashF(out, outOffset, out, outOffset, pubSeed, bbaddr);
    }
  }

  /// Expands seed into WOTS private key
  static void expandSeed(Uint8List outSeeds, Uint8List inSeed) {
    for (int i = 0; i < WOTSLEN; i++) {
      final ctr = Uint8List(4);
      ctr.buffer.asByteData().setUint32(0, i, Endian.big);
      WOTSHash.prf(outSeeds, i * PARAMSN, ctr, inSeed);
    }
  }

  /// Converts message to base w (convenience overload)
  static List<int> baseW(Uint8List msg, List<int> destination) {
    return baseW_(msg, destination, 0, destination.length);
  }

  /// Converts message to base w
  static List<int> baseW_(
    Uint8List msg,
    List<int> destination,
    int offset,
    int length,
  ) {
    int inIdx = 0;
    int outIdx = 0;
    int total = 0;
    int bits = 0;

    for (int consumed = 0; consumed < length; consumed++) {
      if (bits == 0) {
        total = msg[inIdx++];
        bits += 8;
      }
      bits -= WOTSLOGW;
      destination[outIdx + offset] = (total >> bits) & (WOTSW - 1);
      outIdx++;
    }

    return destination;
  }

  /// Computes WOTS checksum
  static List<int> wotsChecksum(List<int> msgBaseW, int sumOffset) {
    int csum = 0;

    // Compute checksum
    for (int i = 0; i < WOTSLEN1; i++) {
      csum += (WOTSW - 1) - msgBaseW[i];
    }

    // Shift left by WOTSLOGW bits
    csum <<= WOTSLOGW;

    // Convert to bytes and base w
    final csumBytes = Uint8List(2);
    csumBytes[0] = (csum >> 8) & 0xFF;
    csumBytes[1] = csum & 0xFF;

    return baseW_(csumBytes, msgBaseW, sumOffset, msgBaseW.length - sumOffset);
  }

  /// Computes chain lengths
  static List<int> chainLengths(Uint8List msg, List<int> destination) {
    final lengths = baseW_(msg, destination, 0, WOTSLEN1);
    return wotsChecksum(lengths, WOTSLEN1);
  }

  /// Generates WOTS public key
  static void wotsPkgen(
    Uint8List pk,
    Uint8List seed,
    Uint8List pubSeed,
    int offset,
    Uint8List addr,
  ) {
    // Expand seed
    expandSeed(pk, seed);

    // Create WotsAddress instance from addr bytes
    final wotsAddr = WotsAddress.wotsAddressFromBytes(addr);
    final bbaddr = ByteBuffer.wrap(wotsAddr.bytes().sublist(0, PARAMSN));
    bbaddr.order(ByteOrder.littleEndian);

    // Generate chains
    for (int i = 0; i < WOTSLEN; i++) {
      WOTSHash.setChainAddr(bbaddr, i);
      genChain(pk, i * PARAMSN, pk, i * PARAMSN, 0, WOTSW - 1,
          pubSeed.sublist(offset), bbaddr.array());
    }
  }

  /// Signs a message using WOTS
  static void wotsSign(
    Uint8List sig,
    Uint8List msg,
    Uint8List seed,
    Uint8List pubSeed,
    int offset,
    Uint8List addr,
  ) {
    final lengths = List<int>.filled(WOTSLEN, 0);

    // Compute lengths
    chainLengths(msg, lengths);

    // Expand seed
    expandSeed(sig, seed);

    // Create WotsAddress instance from addr bytes
    final wotsAddr = WotsAddress.wotsAddressFromBytes(addr);
    final bbaddr = ByteBuffer.wrap(wotsAddr.bytes().sublist(0, PARAMSN));
    bbaddr.order(ByteOrder.littleEndian);

    // Generate signature
    for (int i = 0; i < WOTSLEN; i++) {
      WOTSHash.setChainAddr(bbaddr, i);
      genChain(sig, i * PARAMSN, sig, i * PARAMSN, 0, lengths[i],
          pubSeed.sublist(offset), bbaddr.array());
    }
  }

  /// Verifies a WOTS signature
  static Uint8List wotsPkFromSig(
    Uint8List signature,
    Uint8List msg,
    Uint8List pubSeed,
    Uint8List addr,
  ) {
    final pk = Uint8List(WOTSSIGBYTES);
    final lengths = List<int>.filled(WOTSLEN, 0);

    // Copy and wrap address
    final caddr = Uint8List.fromList(addr);
    final wotsAddr = WotsAddress.wotsAddressFromBytes(caddr);
    final bbaddr = ByteBuffer.wrap(wotsAddr.bytes().sublist(0, PARAMSN));
    bbaddr.order(ByteOrder.littleEndian);

    // Compute lengths
    chainLengths(msg, lengths);

    // Verify signature
    for (int i = 0; i < WOTSLEN; i++) {
      WOTSHash.setChainAddr(bbaddr, i);
      genChain(pk, i * PARAMSN, signature, i * PARAMSN, lengths[i],
          WOTSW - 1 - lengths[i], pubSeed, bbaddr.array());
    }

    return pk;
  }

  /// Generates a WOTS address using the componentsGenerator.
  /// Note: use your own componentsGenerator that fills in deterministic bytes if you want to generate a specific address
  static Uint8List generateAddress(
    Uint8List? tag,
    Uint8List secret,
    Map<String, Uint8List> Function(Uint8List wotsSeed) componentsGenerator,
  ) {
    if (secret.length != PARAMSN) {
      throw ArgumentError('Invalid secret length');
    }
    if (tag != null && tag.length != 12) {
      throw ArgumentError('Invalid tag length');
    }

    final sourcePK = Uint8List(WOTSSIGBYTES);
    final components = componentsGenerator(secret);

    wotsPkgen(sourcePK, components['private_seed']!, components['public_seed']!,
        0, components['addr_seed']!);

    final sourceAddress = Uint8List(2208);
    sourceAddress.setRange(0, WOTSSIGBYTES, sourcePK);
    sourceAddress.setRange(
        WOTSSIGBYTES, WOTSSIGBYTES + 32, components['public_seed']!);
    sourceAddress.setRange(WOTSSIGBYTES + 32, 2208, components['addr_seed']!);

    // Apply tag if provided using Tag.tag
    final readyAddress =
        tag != null ? Tag.tag(sourceAddress, tag) : sourceAddress;

    // Validate address
    for (int i = 0; i < 10; i++) {
      if (!isValid(secret, readyAddress, randomBytes)) {
        throw ArgumentError('Invalid WOTS');
      }
    }

    return readyAddress;
  }

  /// Validates WOTS components
  static bool isValidWithComponents(
    Uint8List secret,
    Uint8List pk,
    Uint8List pubSeed,
    Uint8List rnd2,
    RandomGenerator randomGenerator,
  ) {
    if (secret.length != PARAMSN) {
      throw ArgumentError('Invalid secret length');
    }
    if (pk.length != WOTSSIGBYTES) {
      throw ArgumentError('Invalid pk length');
    }
    if (pubSeed.length != PARAMSN) {
      throw ArgumentError('Invalid pubSeed length');
    }
    if (rnd2.length != PARAMSN) {
      throw ArgumentError('Invalid rnd2 length');
    }

    // Generate random message
    final msg = Uint8List(PARAMSN);
    randomGenerator(msg);

    // Sign message
    final sig = Uint8List(WOTSSIGBYTES);
    wotsSign(sig, msg, secret, pubSeed, 0, rnd2);

    // Verify signature
    final computedPk = wotsPkFromSig(sig, msg, pubSeed, rnd2);

    // Compare public keys
    return _compareBytes(computedPk, pk);
  }

  /// Splits a WOTS address into its components
  static void splitAddress(
    Uint8List address,
    Uint8List pk,
    Uint8List pubSeed,
    Uint8List rnd2,
    Uint8List? tag,
  ) {
    if (address.length != 2208) {
      throw ArgumentError('Invalid address length');
    }
    if (pk.length != WOTSSIGBYTES) {
      throw ArgumentError('Invalid pk length');
    }
    if (pubSeed.length != PARAMSN) {
      throw ArgumentError('Invalid pubSeed length');
    }
    if (rnd2.length != PARAMSN) {
      throw ArgumentError('Invalid rnd2 length');
    }
    if (tag != null && tag.length != 12) {
      throw ArgumentError('Invalid tag length');
    }

    // Copy components
    pk.setRange(0, WOTSSIGBYTES, address, 0);
    pubSeed.setRange(0, PARAMSN, address, WOTSSIGBYTES);
    rnd2.setRange(0, PARAMSN, address, WOTSSIGBYTES + PARAMSN);

    // Copy tag if provided
    if (tag != null) {
      tag.setRange(0, 12, rnd2, 20);
    }
  }

  /// Validates a WOTS address using a Random generator
  static bool isValid(Uint8List secret, Uint8List address,
      [RandomGenerator random = randomBytes]) {
    final pk = Uint8List(WOTSSIGBYTES);
    final pubSeed = Uint8List(PARAMSN);
    final rnd2 = Uint8List(PARAMSN);

    splitAddress(address, pk, pubSeed, rnd2, null);
    return isValidWithComponents(secret, pk, pubSeed, rnd2, random);
  }

  /// Generates a random WOTS address using the randomGenerator
  /// Note: use your own randomGenerator that fills in deterministic bytes if you want to generate a specific address
  static Uint8List generateRandomAddress(
    Uint8List? tag,
    Uint8List secret, [
    RandomGenerator randomGenerator = randomBytes,
  ]) {
    if (secret.length != PARAMSN) {
      throw ArgumentError('Invalid secret length');
    }
    if (tag != null && tag.length != 12) {
      throw ArgumentError('Invalid tag length');
    }

    final address = Uint8List(2208);
    final rnd2 = Uint8List(PARAMSN);

    // Generate random bytes for address
    randomGenerator(address);

    // Copy random bytes to rnd2
    rnd2.setRange(0, PARAMSN, address, 2176);

    // Generate public key
    wotsPkgen(address, secret,
        address.sublist(WOTSSIGBYTES, WOTSSIGBYTES + PARAMSN), 0, rnd2);

    // Copy rnd2 back to address
    address.setRange(2176, 2208, rnd2);

    // Apply tag if provided using Tag.tag
    final readyAddress = tag != null ? Tag.tag(address, tag) : address;

    // Validate address
    for (int i = 0; i < 10; i++) {
      if (!isValid(secret, readyAddress, randomGenerator)) {
        throw ArgumentError('Invalid WOTS');
      }
    }

    return readyAddress;
  }

  /// Helper function to compare two byte arrays
  static bool _compareBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Default random bytes generator
void randomBytes(Uint8List bytes) {
  final rnd = Random.secure();
  for (int i = 0; i < bytes.length; i++) {
    bytes[i] = rnd.nextInt(256);
  }
}
