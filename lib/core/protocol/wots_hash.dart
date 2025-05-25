import 'dart:typed_data';
import 'package:mochimo_wots/core/model/byte_buffer.dart'; 
import 'package:mochimo_wots/core/hasher/mochimo_hasher.dart'; 

// Type alias for ByteArray for consistency
typedef ByteArray = Uint8List;

/**
 * WOTS Hash Chain Implementation
 */
class WOTSHash {
  // XMSS hash padding constants
  static const int XMSS_HASH_PADDING_F = 0;
  static const int XMSS_HASH_PADDING_PRF = 3;

  // Private constructor to prevent instantiation of a utility class
  WOTSHash._();

  /**
   * Set chain address in the address buffer.
   * Modifies the provided ByteBuffer's position and writes the chain value.
   *
   * @param addr The ByteBuffer representing the address.
   * @param chain The chain address value (integer).
   */
  static void setChainAddr(ByteBuffer addr, int chain) {
    addr.position(20); // Set position to byte 20
    addr.putInt(chain); // Write the integer value
  }

  /**
   * Set hash address in the address buffer.
   * Modifies the provided ByteBuffer's position and writes the hash value.
   *
   * @param addr The ByteBuffer representing the address.
   * @param hash The hash address value (integer).
   */
  static void setHashAddr(ByteBuffer addr, int hash) {
    addr.position(24); // Set position to byte 24
    addr.putInt(hash); // Write the integer value
  }

  /**
   * Set key and mask in the address buffer.
   * Modifies the provided ByteBuffer's position and writes the keyAndMask value.
   *
   * @param addr The ByteBuffer representing the address.
   * @param keyAndMask The key and mask value (integer).
   */
  static void setKeyAndMask(ByteBuffer addr, int keyAndMask) {
    addr.position(28); // Set position to byte 28
    addr.putInt(keyAndMask); // Write the integer value
  }

  /**
   * Convert address buffer to bytes in little-endian format.
   * This function reads bytes from the ByteBuffer and manually reorders them
   * to produce a little-endian byte array, assuming the ByteBuffer's `get_()`
   * method reads bytes in the order they were put (likely big-endian if `putInt`
   * was used with `BIG_ENDIAN` order, or just sequential).
   *
   * @param addr The ByteBuffer containing the address data.
   * @returns A ByteArray (Uint8List) representing the address in little-endian format.
   */
  static ByteArray addrToBytes(ByteBuffer addr) {
    addr.position(0); // Reset position to the beginning of the buffer
    final littleEndians = Uint8List(addr.capacity()); // Create a new Uint8List of the same capacity

    // Loop through the buffer, reading 4 bytes at a time and reordering them
    // from big-endian (as read by get_()) to little-endian in the output array.
    for (int i = 0; i < littleEndians.length; i += 4) {
      final int b0 = addr.get_(); // Read byte 0 (most significant if big-endian)
      final int b1 = addr.get_(); // Read byte 1
      final int b2 = addr.get_(); // Read byte 2
      final int b3 = addr.get_(); // Read byte 3 (least significant if big-endian)

      // Place them in little-endian order in the output array
      littleEndians[i] = b3;
      littleEndians[i + 1] = b2;
      littleEndians[i + 2] = b1;
      littleEndians[i + 3] = b0;
    }

    return littleEndians;
  }

  /**
   * PRF (Pseudo-Random Function) implementation.
   * This function calculates a hash based on padding, a key, and an input.
   *
   * @param out The output ByteArray to write the hash into.
   * @param offset The offset in the output array to start writing.
   * @param input The input ByteArray for the PRF.
   * @param key The key ByteArray for the PRF.
   * @returns The modified output ByteArray.
   */
  static ByteArray prf(ByteArray out, int offset, ByteArray input, ByteArray key) {
    // Create a buffer of 96 bytes for hashing (32 bytes padding + 32 bytes key + 32 bytes input)
    final buff = Uint8List(96);

    // Add padding (XMSS_HASH_PADDING_PRF at the last byte of the first 32-byte block)
    final padding = Uint8List(32);
    padding[31] = XMSS_HASH_PADDING_PRF;
    buff.setAll(0, padding); // Copy padding to the beginning of the buffer

    // Add key to the buffer, starting at byte 32
    buff.setAll(32, key);

    // Add input to the buffer, starting at byte 64
    buff.setAll(64, input);

    // Hash the combined buffer and copy the result to the output array
    final hasher = MochimoHasher(); // Create a new hasher instance
    hasher.update(buff); // Update hasher with the combined buffer
    final hash = hasher.digest(); // Get the hash digest
    out.setAll(offset, hash); // Copy the hash to the specified offset in the output array

    return out;
  }

  /**
   * F hash function (used in WOTS+).
   * This function calculates a hash based on padding, a key derived from pubSeed and addr,
   * an input XORed with a bitmask, and then hashes the combined data.
   *
   * @param out The output ByteArray to write the hash into.
   * @param outOffset The offset in the output array to start writing.
   * @param input The input ByteArray for the hash function.
   * @param inOffset The offset in the input array to start reading.
   * @param pubSeed The public seed ByteArray.
   * @param addr The ByteBuffer representing the address.
   */
  static void thashF(
    ByteArray out,
    int outOffset,
    ByteArray input,
    int inOffset,
    ByteArray pubSeed,
    ByteBuffer addr,
  ) {
    // Create a buffer of 96 bytes for hashing
    final buf = Uint8List(96);

    // Add padding (XMSS_HASH_PADDING_F at the last byte of the first 32-byte block)
    final padding = Uint8List(32);
    padding[31] = XMSS_HASH_PADDING_F;
    buf.setAll(0, padding); // Copy padding to the beginning of the buffer

    // Get key: calculate PRF(pubSeed, addr_as_bytes) and store it at buf[32...63]
    setKeyAndMask(addr, 0); // Set keyAndMask to 0 for key derivation
    final addrAsBytesForPrf = addrToBytes(addr); // Convert address buffer to bytes
    prf(buf, 32, addrAsBytesForPrf, pubSeed); // Calculate PRF and write to buf starting at offset 32

    // Get mask: calculate PRF(pubSeed, addr_as_bytes_with_mask_set)
    setKeyAndMask(addr, 1); // Set keyAndMask to 1 for mask derivation
    final addrAsBytesForMask = addrToBytes(addr); // Convert address buffer to bytes
    final bitmask = Uint8List(32); // Create a temporary buffer for the bitmask
    prf(bitmask, 0, addrAsBytesForMask, pubSeed); // Calculate PRF for the bitmask

    // XOR input with bitmask and store in buf starting at byte 64
    for (int i = 0; i < 32; i++) {
      buf[64 + i] = input[i + inOffset] ^ bitmask[i];
    }

    // Hash the combined buffer and copy the result to the output array
    final hasher = MochimoHasher(); // Create a new hasher instance
    hasher.update(buf); // Update hasher with the combined buffer
    final hash = hasher.digest(); // Get the hash digest
    out.setAll(outOffset, hash); // Copy the hash to the specified offset in the output array
  }
}