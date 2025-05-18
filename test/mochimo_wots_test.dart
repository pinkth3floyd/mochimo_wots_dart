import 'package:flutter_test/flutter_test.dart';
import 'package:mochimo_wots/core/hasher/MochimoHasher.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

Uint8List getNodeHash(Uint8List data) {
  return Uint8List.fromList(sha256.convert(data).bytes);
}

void main() {
  group('MochimoHasher', () {
    group('basic operations', () {
      test('should match Node crypto for empty buffer', () {
        final hasher = MochimoHasher();
        final result = hasher.digest();
        final expected = getNodeHash(Uint8List(0));
        expect(result, equals(expected));
      });

      test('should match Node crypto for simple data', () {
        final data = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
        final hasher = MochimoHasher();
        hasher.update(data);
        expect(hasher.digest(), equals(getNodeHash(data)));
      });

      test('should handle single byte', () {
        final data = Uint8List.fromList([0xFF]);
        final hasher = MochimoHasher();
        hasher.update(data);
        expect(hasher.digest(), equals(getNodeHash(data)));
      });

      test('should handle non-aligned data length', () {
        final data = Uint8List.fromList([0x12, 0x34, 0x56]); // 3 bytes
        final hasher = MochimoHasher();
        hasher.update(data);
        expect(hasher.digest(), equals(getNodeHash(data)));
      });
    });

    group('multiple updates', () {
      test('should match Node crypto for multiple updates', () {
        final data1 = Uint8List.fromList([0x12, 0x34]);
        final data2 = Uint8List.fromList([0x56, 0x78]);

        final hasher = MochimoHasher();
        hasher.update(data1);
        hasher.update(data2);

        final combinedData = [...data1, ...data2];
        expect(hasher.digest(), equals(Uint8List.fromList(sha256.convert(combinedData).bytes)));
      });

      test('should handle mixed-size updates', () {
        final data1 = Uint8List.fromList([0x12]);
        final data2 = Uint8List.fromList([0x34, 0x56]);
        final data3 = Uint8List.fromList([0x78, 0x9A, 0xBC, 0xDE]);

        final hasher = MochimoHasher();
        hasher.update(data1);
        hasher.update(data2);
        hasher.update(data3);

        final combinedData = [...data1, ...data2, ...data3];
        expect(hasher.digest(), equals(Uint8List.fromList(sha256.convert(combinedData).bytes)));
      });

      test('should handle zero-length updates', () {
        final data1 = Uint8List.fromList([0x12, 0x34]);
        final data2 = Uint8List(0);
        final data3 = Uint8List.fromList([0x56, 0x78]);

        final hasher = MochimoHasher();
        hasher.update(data1);
        hasher.update(data2);
        hasher.update(data3);

        final combinedData = [...data1, ...data2, ...data3];
        expect(hasher.digest(), equals(Uint8List.fromList(sha256.convert(combinedData).bytes)));
      });
    });

    group('error cases', () {
      test('should handle multiple digests', () {
        final data = Uint8List.fromList([0x12, 0x34]);
        final hasher = MochimoHasher();
        hasher.update(data);
        final result1 = hasher.digest();
        final result2 = hasher.digest(); // Should be empty hash
        expect(result2, equals(getNodeHash(Uint8List(0))));
      });
    });

    group('edge cases', () {
      test('should handle data with undefined bytes in word boundary', () {
        // Create data that will have undefined bytes when creating words (if the underlying impl does word-based processing)
        final data = Uint8List(5); // 5 bytes
        data[0] = 0x12;
        data[1] = 0x34;
        data[2] = 0x56;
        data[3] = 0x78;
        data[4] = 0x9A;

        final hasher = MochimoHasher();
        hasher.update(data);
        expect(hasher.digest(), equals(getNodeHash(data)));
      });

      test('should handle data with exactly one word', () {
        final data = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
        final hasher = MochimoHasher();
        hasher.update(data);
        expect(hasher.digest(), equals(getNodeHash(data)));
      });

      test('should handle data with partial words', () {
        final data = Uint8List.fromList([0x12, 0x34, 0x56]); // 3 bytes
        final hasher = MochimoHasher();
        hasher.update(data);
        expect(hasher.digest(), equals(getNodeHash(data)));
      });

      test('should handle data spanning multiple words with partial end', () {
        final data = Uint8List.fromList([
          0x12, 0x34, 0x56, 0x78, // first word
          0x9A, 0xBC, 0xDE, 0xF0, // second word
          0x11, 0x22, 0x33, // partial third word
        ]);
        final hasher = MochimoHasher();
        hasher.update(data);
        expect(hasher.digest(), equals(getNodeHash(data)));
      });
    });
  });
}
