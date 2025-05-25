import 'dart:typed_data';
import 'package:pointycastle/digests/sha3.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:pointycastle/digests/sha256.dart';

// Define a type alias for ByteArray, since Dart doesn't have a direct equivalent
typedef ByteArray = Uint8List;

/// Dart implementation of MochimoHasher
/// Uses the pointycastle package for hash implementations
class MochimoHasher {
  late dynamic _hasher; // pointycastle Digest
  final String _algorithm;
  final List<int> _buffer = []; // Buffer to accumulate data

  MochimoHasher({String algorithm = 'sha256'}) : _algorithm = algorithm.toLowerCase() {
    _hasher = _createHasher(_algorithm);
  }

  dynamic _createHasher(String algorithm) {
    switch (algorithm) {
      case 'sha256':
        return SHA256Digest();
      case 'sha3-512':
        return SHA3Digest(512);
      case 'ripemd160':
        return RIPEMD160Digest();
      default:
        throw ArgumentError('Unsupported hash algorithm: $algorithm');
    }
  }

  /// Updates the hash with the given data
  void update(ByteArray buffer, [int offset = 0, int? length]) {
    length ??= buffer.length;
    if (offset < 0 || offset > buffer.length) {
      throw ArgumentError('Invalid offset');
    }
    if (length < 0 || offset + length > buffer.length) {
      throw ArgumentError('Invalid length');
    }

    final data = buffer.sublist(offset, offset + length);
    if (_buffer.isEmpty) {
      _hasher.reset();
    }
    _buffer.addAll(data);
  }

  /// Returns the final hash value
  ByteArray digest() {
    final data = Uint8List.fromList(_buffer);
    _hasher.update(data, 0, data.length);
    final digestBytes = Uint8List(_hasher.digestSize);
    _hasher.doFinal(digestBytes, 0);
    _buffer.clear();
    _hasher.reset();
    return digestBytes;
  }

  /// Performs hash operation
  static ByteArray hash(ByteArray data, [int? offset, int? length]) {
    final hasher = MochimoHasher();
    if (offset != null && length != null) {
      hasher.update(data, offset, length);
    } else {
      hasher.update(data);
    }
    return hasher.digest();
  }

  /// Performs hash operation with specified algorithm
  static ByteArray hashWith(String algorithm, ByteArray data) {
    final hasher = MochimoHasher(algorithm: algorithm);
    hasher.update(data);
    return hasher.digest();
  }
}
