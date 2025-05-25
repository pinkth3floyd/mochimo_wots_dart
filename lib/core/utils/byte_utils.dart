import 'dart:typed_data';
import 'package:mochimo_wots/core/model/ByteBuffer.dart';



typedef ByteArray = Uint8List;
typedef HexString = String;


class ByteUtils {
  // Private constructor to prevent instantiation
  ByteUtils._();

  /// Hexadecimal characters for byte-to-hex conversion
  static const hexChars = '0123456789abcdef';

  /// Create a copy of a byte array
  static ByteArray copyOf(ByteArray original, int length) {
    final copy = Uint8List(length);
    final copyLength = original.length < length ? original.length : length;
    copy.setRange(0, copyLength, original);
    return copy;
  }

  /// Convert a hexadecimal string to a byte array
  static ByteArray hexToBytes(HexString hex) {
    String cleanHex = hex.toLowerCase();
    if (cleanHex.startsWith('0x')) {
      cleanHex = cleanHex.substring(2);
    }
    if (cleanHex.length % 2 != 0) {
      cleanHex = '0' + cleanHex;
    }
    final bytes = Uint8List(cleanHex.length ~/ 2);
    for (int i = 0; i < cleanHex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(cleanHex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  /// Compares two byte arrays
  static bool compareBytes(ByteArray a, ByteArray b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Reads little-endian unsigned values from a buffer
  static BigInt readLittleEndianUnsigned(ByteBuffer buffer, [int bytes = 8]) {
    final temp = Uint8List(bytes);
    buffer.get(temp);
    BigInt value = BigInt.zero;
    for (int i = bytes - 1; i >= 0; i--) {
      value = (value << 8) | BigInt.from(temp[i]);
    }
    return value;
  }

  /// Trims address for display
  static String trimAddress(String addressHex) {
    return '${addressHex.substring(0, 32)}...${addressHex.substring(addressHex.length - 24)}';
  }

  /// Converts number to little-endian bytes
  static ByteArray numberToLittleEndian(int value, int length) {
    final bytes = Uint8List(length);
    int remaining = value;
    for (int i = 0; i < length; i++) {
      bytes[i] = remaining & 0xFF;
      remaining = remaining >> 8;
    }
    return bytes;
  }

  /// Converts byte array to little-endian
  static ByteArray bytesToLittleEndian(ByteArray bytes) {
    final result = Uint8List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      result[i] = bytes[bytes.length - 1 - i];
    }
    return result;
  }

  /// Fits byte array or string to specified length
  static ByteArray fit(dynamic bytes, int length) {
    if (bytes is String) {
      final value = BigInt.parse(bytes);
      final result = Uint8List(length);
      BigInt remaining = value;
      for (int i = 0; i < length; i++) {
        result[i] = (remaining & BigInt.from(0xff)).toInt();
        remaining = remaining >> 8;
      }
      return result;
    } else if (bytes is ByteArray) {
      final result = Uint8List(length);
      final copyLength = bytes.length < length ? bytes.length : length;
      result.setRange(0, copyLength, bytes);
      return result;
    } else {
      throw ArgumentError('Input must be a String or ByteArray');
    }
  }

  /// Convert a byte array to its hexadecimal string representation
  static HexString bytesToHex(ByteArray bytes, [int offset = 0, int? length]) {
    length ??= bytes.length - offset;
    if (offset < 0 || offset > bytes.length) {
      throw ArgumentError('Invalid offset: $offset');
    }
    if (length < 0 || offset + length > bytes.length) {
      throw ArgumentError('Invalid length: $length');
    }
    final hexChars = List<String>.filled(length * 2, '');
    for (int j = 0; j < length; j++) {
      final v = bytes[j + offset] & 0xFF;
      hexChars[j * 2] = ByteUtils.hexChars[v >> 4];
      hexChars[j * 2 + 1] = ByteUtils.hexChars[v & 0x0F];
    }
    return hexChars.join();
  }

  /// Convert a number to a byte array of specified length
  static ByteArray toBytes(dynamic value, int length) {
    String hex;
    if (value is int) {
      hex = value.toRadixString(16).padLeft(length * 2, '0');
    } else if (value is BigInt) {
      hex = value.toRadixString(16).padLeft(length * 2, '0');
    } else {
      throw ArgumentError('Value must be int or BigInt');
    }
    return ByteUtils.hexToBytes(hex);
  }

  /// Convert a byte array to little-endian format
  static ByteArray toLittleEndian(ByteArray value, [int offset = 0, int? length]) {
    length ??= value.length - offset;
    if (offset < 0 || offset > value.length) {
      throw ArgumentError('Invalid offset: $offset');
    }
    if (length < 0 || offset + length > value.length) {
      throw ArgumentError('Invalid length: $length');
    }
    final copy = Uint8List(length);
    copy.setRange(0, length, value, offset);
    for (int i = 0; i < (copy.length >> 1); i++) {
      final temp = copy[i];
      copy[i] = copy[copy.length - i - 1];
      copy[copy.length - i - 1] = temp;
    }
    return copy;
  }

  /// Clear a byte array by filling it with zeros
  static void clear(ByteArray data) {
    data.fillRange(0, data.length, 0);
  }

  /// Compare two byte arrays for equality
  static bool areEqual(ByteArray a, ByteArray b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}