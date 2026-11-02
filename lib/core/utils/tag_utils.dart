import 'dart:typed_data';
import 'package:base58check/base58.dart';
import 'crc16.dart';

typedef ByteArray = Uint8List;

class TagUtils {
  TagUtils._(); // coverage:ignore-line

  /// Base58 alphabet used for Mochimo account tags.
  static const _base58 =
      Base58Codec('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz');

  /// Converts a 20-byte account tag to Base58 with a CRC-16/XMODEM checksum.
  ///
  /// The encoded payload is 22 bytes: the tag, then the checksum in
  /// little-endian, matching `put16` in the node.
  static String? addrTagToBase58(ByteArray? addrTag) {
    if (addrTag == null) return null;
    if (addrTag.length != 20) {
      throw ArgumentError(
          'Invalid address tag length: ${addrTag.length}. Expected 20.');
    }

    final csum = CRC16.crc(addrTag, 0, 20);
    final combined = Uint8List(22);
    combined.setRange(0, 20, addrTag);
    combined[20] = csum & 0xFF;
    combined[21] = (csum >> 8) & 0xFF;

    return _base58.encode(combined);
  }

  /// Validates a Base58 encoded address tag with CRC16 checksum
  static bool validateBase58Tag(String tag) {
    try {
      final decoded = _base58.decode(tag);
      if (decoded.length != 22) return false;

      final storedCsum = (decoded[21] << 8) | decoded[20];
      final actualCrc =
          CRC16.crc(Uint8List.fromList(decoded.sublist(0, 20)), 0, 20);

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
    if (decoded.length != 22) {
      throw ArgumentError(
          'Invalid base58 tag length: ${decoded.length}. Expected 22.');
    }
    return Uint8List.fromList(decoded.sublist(0, 20));
  }
}
