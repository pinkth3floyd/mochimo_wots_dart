import 'dart:typed_data';

/**
 * ByteOrder enum to match Java's ByteOrder
 */
enum ByteOrder {
  BIG_ENDIAN,
  LITTLE_ENDIAN
}

/**
 * Dart implementation of Java's ByteBuffer
 */
class ByteBuffer {
  late Uint8List _buf;
  int _pos = 0;
  ByteOrder _byteOrder = ByteOrder.BIG_ENDIAN;

  ByteBuffer._internal(int capacity) {
    _buf = Uint8List(capacity);
  }

  /**
   * Creates a new ByteBuffer with the given capacity
   */
  static ByteBuffer allocate(int capacity) {
    return ByteBuffer._internal(capacity);
  }

  /**
   * Creates a new ByteBuffer that wraps the given array
   */
  static ByteBuffer wrap(Uint8List array) {
    final buffer = ByteBuffer._internal(array.length);
    buffer._buf.setAll(0, array);
    return buffer;
  }

  /**
   * Sets this buffer's byte order
   */
  ByteBuffer order(ByteOrder order) {
    _byteOrder = order;
    return this;
  }

  /**
   * Sets or gets this buffer's position
   */
  dynamic position([int? newPosition]) {
    if (newPosition == null) {
      return _pos;
    }
    if (newPosition < 0 || newPosition > _buf.length) {
      throw RangeError('Invalid position, position: $newPosition, length: ${_buf.length}');
    }
    _pos = newPosition;
    return this;
  }

  /**
   * Returns this buffer's capacity
   */
  int capacity() {
    return _buf.length;
  }

  /**
   * Writes a byte or bytes into this buffer
   */
  ByteBuffer put(dynamic input, [int offset = 0, int? length]) {
    if (input is int) {
      if (_pos >= _buf.length) {
        throw RangeError('Buffer overflow');
      }
      _buf[_pos++] = input & 0xFF;
      return this;
    }

    if (input is Uint8List) {
      final srcOffset = offset;
      final srcLength = length ?? input.length;

      if (srcOffset < 0 || srcOffset > input.length) {
        throw RangeError('Invalid offset');
      }
      if (srcLength < 0 || srcOffset + srcLength > input.length) {
        throw RangeError('Invalid length');
      }
      if (_pos + srcLength > _buf.length) {
        throw RangeError('Buffer overflow');
      }

      _buf.setRange(_pos, _pos + srcLength, input, srcOffset);
      _pos += srcLength;
      return this;
    }

    throw ArgumentError('Input must be an int or Uint8List');
  }

  /**
   * Writes an integer into this buffer
   */
  ByteBuffer putInt(int value) {
    if (_pos + 4 > _buf.length) {
      throw RangeError('Buffer overflow');
    }

    if (_byteOrder == ByteOrder.BIG_ENDIAN) {
      _buf[_pos++] = (value >>> 24) & 0xFF;
      _buf[_pos++] = (value >>> 16) & 0xFF;
      _buf[_pos++] = (value >>> 8) & 0xFF;
      _buf[_pos++] = value & 0xFF;
    } else {
      _buf[_pos++] = value & 0xFF;
      _buf[_pos++] = (value >>> 8) & 0xFF;
      _buf[_pos++] = (value >>> 16) & 0xFF;
      _buf[_pos++] = (value >>> 24) & 0xFF;
    }

    return this;
  }

  /**
   * Gets bytes from the buffer into the destination array
   */
  ByteBuffer get(Uint8List dst) {
    // Check if we have enough bytes
    if (_pos + dst.length > _buf.length) {
      throw RangeError('Buffer underflow');
    }

    // Copy bytes from current position to destination
    for (int i = 0; i < dst.length; i++) {
      dst[i] = _buf[_pos++];
    }
    return this;
  }

  /**
   * Gets a single byte from the buffer
   */
  int get_() {
    if (_pos >= _buf.length) {
      throw RangeError('Buffer underflow');
    }
    return _buf[_pos++];
  }

  /**
   * Returns a copy of the backing array
   */
  Uint8List array() {
    return Uint8List.fromList(_buf);
  }

  /**
   * Rewinds this buffer. Sets the position to zero
   */
  ByteBuffer rewind() {
    _pos = 0;
    return this;
  }
}

// Common type aliases used throughout the codebase
typedef byte = int; // Java byte in Dart
typedef ByteArray = Uint8List; // Java byte[] in Dart
typedef BigIntD = BigInt; // Java BigInteger in Dart

// Utility type for hex strings
typedef HexString = String;