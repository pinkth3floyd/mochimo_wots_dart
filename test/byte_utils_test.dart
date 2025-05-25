import 'package:test/test.dart';
import 'dart:typed_data';
import 'package:mochimo_wots/core/utils/byte_utils.dart';

void main() {
  group('ByteUtils', () {
    group('copyOf', () {
      test('should create a copy of byte array with specified length', () {
        final original = Uint8List.fromList([1, 2, 3, 4, 5]);
        final copy = ByteUtils.copyOf(original, 3);
        expect(copy, Uint8List.fromList([1, 2, 3]));
        expect(copy.length, 3);
      });

      test('should pad with zeros if length is greater than original', () {
        final original = Uint8List.fromList([1, 2, 3]);
        final copy = ByteUtils.copyOf(original, 5);
        expect(copy, Uint8List.fromList([1, 2, 3, 0, 0]));
        expect(copy.length, 5);
      });
    });

    group('hexToBytes', () {
      test('should convert hex string to bytes', () {
        final hex = 'deadbeef';
        final bytes = ByteUtils.hexToBytes(hex);
        expect(bytes, Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]));
      });

      test('should handle 0x prefix', () {
        final hex = '0xdeadbeef';
        final bytes = ByteUtils.hexToBytes(hex);
        expect(bytes, Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]));
      });

      test('should handle odd length by padding with leading zero', () {
        final hex = 'deadb';
        final bytes = ByteUtils.hexToBytes(hex);
        expect(bytes, Uint8List.fromList([0x0d, 0xea, 0xdb]));
      });
    });

    group('bytesToHex', () {
      test('should convert bytes to hex string', () {
        final bytes = Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]);
        final hex = ByteUtils.bytesToHex(bytes);
        expect(hex, 'deadbeef');
      });

      test('should handle offset and length parameters', () {
        final bytes = Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]);
        final hex = ByteUtils.bytesToHex(bytes, 1, 2);
        expect(hex, 'adbe');
      });
    });

    group('compareBytes', () {
      test('should return true for identical arrays', () {
        final a = Uint8List.fromList([1, 2, 3]);
        final b = Uint8List.fromList([1, 2, 3]);
        expect(ByteUtils.compareBytes(a, b), isTrue);
      });

      test('should return false for different arrays', () {
        final a = Uint8List.fromList([1, 2, 3]);
        final b = Uint8List.fromList([1, 2, 4]);
        expect(ByteUtils.compareBytes(a, b), isFalse);
      });

      test('should return false for arrays of different lengths', () {
        final a = Uint8List.fromList([1, 2, 3]);
        final b = Uint8List.fromList([1, 2]);
        expect(ByteUtils.compareBytes(a, b), isFalse);
      });
    });

    group('numberToLittleEndian', () {
      test('should convert number to little-endian bytes', () {
        final result = ByteUtils.numberToLittleEndian(0x12345678, 4);
        expect(result, Uint8List.fromList([0x78, 0x56, 0x34, 0x12]));
      });

      test('should handle smaller lengths', () {
        final result = ByteUtils.numberToLittleEndian(0x1234, 2);
        expect(result, Uint8List.fromList([0x34, 0x12]));
      });
    });

    group('fit', () {
      test('should fit byte array to specified length', () {
        final bytes = Uint8List.fromList([1, 2, 3, 4]);
        final result = ByteUtils.fit(bytes, 6);
        expect(result, Uint8List.fromList([1, 2, 3, 4, 0, 0]));
      });

      test('should truncate if input is longer than specified length', () {
        final bytes = Uint8List.fromList([1, 2, 3, 4]);
        final result = ByteUtils.fit(bytes, 2);
        expect(result, Uint8List.fromList([1, 2]));
      });

      test('should handle string input', () {
        final result = ByteUtils.fit('256', 2);
        expect(result, Uint8List.fromList([0x00, 0x01]));
      });
    });

    group('toLittleEndian', () {
      test('should convert byte array to little-endian', () {
        final bytes = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
        final result = ByteUtils.toLittleEndian(bytes);
        expect(result, Uint8List.fromList([0x78, 0x56, 0x34, 0x12]));
      });

      test('should handle offset and length parameters', () {
        final bytes = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
        final result = ByteUtils.toLittleEndian(bytes, 1, 2);
        expect(result, Uint8List.fromList([0x56, 0x34]));
      });
    });

    group('trimAddress', () {
      test('should trim address correctly', () {
        const address =
            '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
        final trimmed = ByteUtils.trimAddress(address);
        expect(trimmed,
            '1234567890abcdef1234567890abcdef...90abcdef1234567890abcdef');
      });
    });

    group('clear', () {
      test('should clear byte array by filling with zeros', () {
        final bytes = Uint8List.fromList([1, 2, 3, 4]);
        ByteUtils.clear(bytes);
        expect(bytes, Uint8List.fromList([0, 0, 0, 0]));
      });
    });

    group('areEqual', () {
      test('should return true for equal arrays', () {
        final a = Uint8List.fromList([1, 2, 3]);
        final b = Uint8List.fromList([1, 2, 3]);
        expect(ByteUtils.compareBytes(a, b), isTrue);
      });

      test('should return false for different arrays', () {
        final a = Uint8List.fromList([1, 2, 3]);
        final b = Uint8List.fromList([1, 2, 4]);
        expect(ByteUtils.compareBytes(a, b), isFalse);
      });

      test('should return false for arrays of different lengths', () {
        final a = Uint8List.fromList([1, 2, 3]);
        final b = Uint8List.fromList([1, 2]);
        expect(ByteUtils.compareBytes(a, b), isFalse);
      });
    });

    // group('readLittleEndianUnsigned', () {
    //   test('should read little-endian unsigned value from buffer', () {
    //     // Create a mock ByteBuffer
    //     final buffer = MockByteBuffer(Uint8List.fromList([0x78, 0x56, 0x34, 0x12, 0x00, 0x00, 0x00, 0x00]));
    //     final result = ByteUtils.readLittleEndianUnsigned(buffer);
    //     expect(result, BigInt.from(0x12345678));
    //   });
    // });
  });
}
