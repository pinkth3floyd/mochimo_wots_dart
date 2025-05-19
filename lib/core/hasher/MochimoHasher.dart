import 'dart:typed_data';
import 'package:crypto/crypto.dart'; // Import the crypto package
// import 'dart:convert'; // For utf8.encode

// Define a type alias for ByteArray, since Dart doesn't have a direct equivalent
typedef ByteArray = Uint8List;

/**
 * Dart implementation of MochimoHasher
 * Uses the crypto package for hash implementations
 */
class MochimoHasher {
  late Hash _hasher; // Use the abstract Hash class from crypto
  final String _algorithm;
  final List<int> _buffer = []; // Buffer to accumulate data

  MochimoHasher({String algorithm = 'sha256'}) : _algorithm = algorithm {
    _hasher = _createHasher(algorithm);
  }

  Hash _createHasher(String algorithm) {
    switch (algorithm.toLowerCase()) {
      case 'sha256':
        return sha256;
      default:
        throw ArgumentError('Unsupported hash algorithm: $algorithm');
    }
  }

  /**
   * Updates the hash with the given data
   */
  void update(ByteArray buffer, [int offset = 0, int? length]) {
    length ??= buffer.length; // Default length to buffer.length if not provided
    if (offset < 0 || offset > buffer.length) {
      throw ArgumentError('Invalid offset');
    }
    if (length < 0 || offset + length > buffer.length) {
      throw ArgumentError('Invalid length');
    }

    final data = buffer.sublist(offset, offset + length);
    _buffer.addAll(data); // Accumulate data in buffer
  }

  /**
   * Returns the final hash value
   */
  ByteArray digest() {
    final digestBytes = _hasher.convert(_buffer).bytes;
    // Create new hasher for next use and clear buffer
    _hasher = _createHasher(_algorithm);
    _buffer.clear();
    return Uint8List.fromList(digestBytes);
  }

  /**
   * Performs hash operation
   */
  static ByteArray hash(ByteArray data, [int? offset, int? length]) {
    final hasher = MochimoHasher();
    if (offset != null && length != null) {
      hasher.update(data, offset, length);
    } else {
      hasher.update(data);
    }
    return hasher.digest();
  }

  static ByteArray hashWith(String algorithm, ByteArray data) {
    final hasher = MochimoHasher(algorithm: algorithm);
    hasher.update(data);
    return hasher.digest();
  }
}
