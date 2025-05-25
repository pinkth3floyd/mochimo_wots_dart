import 'dart:typed_data';
import 'package:mochimo_wots/core/hasher/mochimo_hasher.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart'; 


typedef ByteArray = Uint8List;


/**
 * WotsAddress implementation for Mochimo addresses
 */
class WotsAddress {
  // Constants
  static const int TXADDRLEN = 40; 
  static const int ADDR_TAG_LEN = 12; 
  static const int WOTS_PK_LEN = 2144;
  static const int TXAMOUNT = 8;
  static const int SHA3LEN512 = 64; 

  late Uint8List _address;
  late BigInt _amount;

  WotsAddress() {
    _address = Uint8List(TXADDRLEN);
    _amount = BigInt.zero;
  }

  /// Returns the combined address and amount as a byte array.
  /// The address occupies the first [TXADDRLEN] bytes,
  /// followed by the amount in [TXAMOUNT] bytes.
  ByteArray bytes() {
    final buffer = Uint8List(TXADDRLEN + TXAMOUNT);
    buffer.setAll(0, _address);
    buffer.setAll(TXADDRLEN, getAmountBytes());
    return buffer;
  }

  /// Extracts and returns the tag portion of the address.
  /// The tag is the first [ADDR_TAG_LEN] bytes of the address.
  ByteArray getTag() {
    return _address.sublist(0, ADDR_TAG_LEN);
  }

  /// Sets the tag portion of the address.
  /// Copies the first [ADDR_TAG_LEN] bytes from the provided tag array.
  /// @param tag The byte array containing the new tag.
  void setTag(ByteArray tag) {
    _address.setAll(0, tag.sublist(0, ADDR_TAG_LEN));
  }

  /// Extracts and returns the address hash portion of the address.
  /// The address hash starts after the tag and extends to [TXADDRLEN].
  ByteArray getAddrHash() {
    return _address.sublist(ADDR_TAG_LEN, TXADDRLEN);
  }

  /// Returns the full address portion (excluding amount).
  ByteArray getAddress() {
    return _address.sublist(0, TXADDRLEN);
  }

  /// Sets the address hash portion of the address.
  /// Copies the first [ADDR_TAG_LEN] bytes from the provided addrHash
  /// into the address hash section.
  /// @param addrHash The byte array containing the new address hash.
  void setAddrHash(ByteArray addrHash) {
    _address.setAll(ADDR_TAG_LEN, addrHash.sublist(0, TXADDRLEN - ADDR_TAG_LEN));
  }

  /// Sets the amount from a byte array.
  /// Reads an 8-byte little-endian unsigned integer from the provided array.
  /// @param amountBytes The byte array representing the amount.
  void setAmountBytes(ByteArray amountBytes) {
    // Ensure the amountBytes array is large enough to read a 64-bit integer
    if (amountBytes.length < TXAMOUNT) {
      throw ArgumentError('Amount bytes array too short. Expected $TXAMOUNT bytes.');
    }
    final byteData = ByteData.view(amountBytes.buffer, amountBytes.offsetInBytes, TXAMOUNT);
    _amount = BigInt.from(byteData.getUint64(0, Endian.little));
  }

  /// Returns the amount as a BigInt.
  BigInt getAmount() {
    return _amount;
  }

  /// Converts the current amount (BigInt) to an 8-byte little-endian array.
  ByteArray getAmountBytes() {
    final buffer = Uint8List(TXAMOUNT);
    final byteData = ByteData.view(buffer.buffer);
    // Convert BigInt to int for putUint64. This assumes the BigInt fits in 64 bits.
    byteData.setUint64(0, _amount.toInt(), Endian.little);
    return buffer;
  }

  /// Creates a [WotsAddress] instance from a byte array.
  /// Handles different byte array lengths representing WOTS public key,
  /// address only, or address with amount.
  /// @param bytes The input byte array.
  /// @returns A new [WotsAddress] instance.
  static WotsAddress wotsAddressFromBytes(ByteArray bytes) {
    final wots = WotsAddress();

    if (bytes.length == WOTS_PK_LEN) {
      final addr = addrFromWots(bytes);
      if (addr != null) {
        // Set the full address
        wots.setTag(addr.sublist(0, ADDR_TAG_LEN));
        wots.setAddrHash(addr.sublist(ADDR_TAG_LEN, TXADDRLEN));
      }
    } else if (bytes.length == TXADDRLEN) {
      // Set the full address
      wots.setTag(bytes.sublist(0, ADDR_TAG_LEN));
      wots.setAddrHash(bytes.sublist(ADDR_TAG_LEN, TXADDRLEN));
    } else if (bytes.length == TXADDRLEN + TXAMOUNT) {
      // Set address and amount separately
      wots.setTag(bytes.sublist(0, ADDR_TAG_LEN));
      wots.setAddrHash(bytes.sublist(ADDR_TAG_LEN, TXADDRLEN));
      wots.setAmountBytes(bytes.sublist(TXADDRLEN));
    }

    return wots;
  }

  /// Creates a [WotsAddress] instance from a hexadecimal string.
  /// @param wotsHex The hexadecimal string representation of the address.
  /// @returns A new [WotsAddress] instance. Returns a default instance if length is invalid.
  static WotsAddress wotsAddressFromHex(String wotsHex) {
    final bytes = ByteUtils.hexToBytes(wotsHex);
    if (bytes.length != TXADDRLEN) {
      return WotsAddress(); // Return a default instance if length is not TXADDRLEN
    }
    return wotsAddressFromBytes(bytes);
  }

  /// Generates an address from an implicit tag.
  /// This function seems to construct a 40-byte address by repeating parts of the tag.
  /// @param tag The input tag byte array.
  /// @returns A new 40-byte address byte array.
  static Uint8List addrFromImplicit(Uint8List tag) {
    final addr = Uint8List(TXADDRLEN);
    // Copy the first ADDR_TAG_LEN bytes of the tag to the beginning of addr
    addr.setAll(0, tag.sublist(0, ADDR_TAG_LEN));
    // Fill the remaining part of the address by repeating the tag bytes
    int remainingLength = TXADDRLEN - ADDR_TAG_LEN;
    for (int i = 0; i < remainingLength; i++) {
      addr[ADDR_TAG_LEN + i] = tag[i % tag.length];
    }
    return addr;
  }

  /// Generates an address hash from an input byte array.
  /// Performs a SHA3-512 hash followed by a RIPEMD160 hash.
  /// @param input The input byte array for hashing.
  /// @returns The calculated address hash as a byte array.
  static Uint8List addrHashGenerate(Uint8List input) {
    // First pass: SHA3-512
    final sha3Hash = MochimoHasher.hashWith('sha3-512', input);

    // Second pass: RIPEMD160
    return MochimoHasher.hashWith('ripemd160', sha3Hash);
  }

  /// Derives an address from a WOTS public key.
  /// @param wots The WOTS public key as a byte array.
  /// @returns The derived address as a byte array, or null if the WOTS public key length is invalid.
  static Uint8List? addrFromWots(Uint8List wots) {
    if (wots.length != WOTS_PK_LEN) {
      return null;
    }
    final hash = addrHashGenerate(wots.sublist(0, WOTS_PK_LEN));
    return addrFromImplicit(hash);
  }
}