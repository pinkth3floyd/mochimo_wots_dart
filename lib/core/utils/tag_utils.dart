import 'dart:typed_data';
import 'package:base58check/base58.dart';
import 'crc16.dart';

typedef ByteArray = Uint8List;

class TagUtils {
  TagUtils._();

  /// Converts an address tag (12 bytes) to a Base58 string with CRC16 checksum
  static const _base58 =
      Base58Codec('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz');

  static String? addrTagToBase58(ByteArray? addrTag) {
    if (addrTag == null) return null;
    if (addrTag.length != 12) {
      throw ArgumentError(
          'Invalid address tag length: ${addrTag.length}. Expected 12.');
    }

    final csum = CRC16.crc(addrTag, 0, 12);
    final combined = Uint8List(
        14); // Changed from 22 to 14 (12 bytes tag + 2 bytes checksum)
    combined.setRange(0, 12, addrTag);

    // Convert csum to little-endian bytes
    combined[12] = csum & 0xFF;
    combined[13] = (csum >> 8) & 0xFF;

    return _base58.encode(combined);
  }

  /// Validates a Base58 encoded address tag with CRC16 checksum
  static bool validateBase58Tag(String tag) {
    try {
      final decoded = _base58.decode(tag);
      if (decoded.length != 14) return false; // 12 bytes tag + 2 bytes checksum

      // Get the stored checksum (last 2 bytes in little-endian)
      final storedCsum = (decoded[13] << 8) | decoded[12];

      // Calculate CRC on the tag portion (first 12 bytes)
      final actualCrc = CRC16.crc(decoded.sublist(0, 12) as Uint8List, 0, 12);

      return storedCsum == actualCrc;
    } catch (e) {
      return false;
    }
  }

  /// Converts a Base58 encoded tag string back to address tag bytes
  static ByteArray? base58ToAddrTag(String tag) {
    if (tag.isEmpty) {
      throw ArgumentError('Input tag cannot be empty.');
    }
    final decoded = _base58.decode(tag);
    if (decoded.length != 14) {
      // 12 bytes tag + 2 bytes checksum
      throw ArgumentError(
          'Invalid base58 tag length: ${decoded.length}. Expected 14.');
    }
    return Uint8List.fromList(decoded.sublist(0, 12));
  }
}
