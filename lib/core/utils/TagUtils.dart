import 'dart:typed_data';
import 'package:base58check/base58.dart';
import 'CRC16.dart';

typedef ByteArray = Uint8List;


class TagUtils {
  TagUtils._();

  /// Converts an address tag (20 bytes) to a Base58 string with CRC16 checksum
  static final Base58Codec _base58 = Base58Codec('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz');

  static String? addrTagToBase58(ByteArray? addrTag) {
    if (addrTag == null) return null;
    if (addrTag.length != 20) {
      throw ArgumentError('Invalid address tag length: ${addrTag.length}. Expected 20.');
    }

    final csum = CRC16.crc(addrTag, 0, 20);
    final combined = Uint8List(22);
    combined.setRange(0, 20, addrTag);

    // Convert csum to little-endian bytes
    combined[20] = csum & 0xFF;
    combined[21] = (csum >> 8) & 0xFF;

    return _base58.encode(combined);
  }

  /// Validates a Base58 encoded address tag with CRC16 checksum
  static bool validateBase58Tag(String tag) {
    try {
      final decoded = _base58.decode(tag);
      if (decoded.length != 22) return false;

      // Get the stored checksum (last 2 bytes in little-endian)
      final storedCsum = (decoded[21] << 8) | decoded[20];

      // Calculate CRC on the tag portion (first 20 bytes)
      final actualCrc = CRC16.crc(decoded.sublist(0, 20) as Uint8List, 0, 20);

      return storedCsum == actualCrc;
    } catch (e) {
      return false;
    }
  }

  /// Converts a Base58 encoded tag string back to address tag bytes
  static ByteArray? base58ToAddrTag(String tag) {
    if (tag == null || tag.isEmpty) {
      throw ArgumentError('Input tag cannot be null or empty.');
    }
    final decoded = _base58.decode(tag);
    if (decoded.length != 22) {
      throw ArgumentError('Invalid base58 tag length: ${decoded.length}. Expected 22.');
    }
    return Uint8List.fromList(decoded.sublist(0, 20));
  }
}


