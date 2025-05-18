import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mochimo_wots/core/utils/TagUtils.dart';

void main() {
  final testVectors = [
    {
      'tag': '3f1fba7025c7d37470e7260117a72b7de9f5ca59',
      'expectedBase58': 'J8gqYehTJhJWrfcUd766sUQ8THktNs'
    },
    {
      'tag': '0000000000000000000000000000000000000000',
      'expectedBase58': '1111111111111111111111'
    }
  ];

  group('TagUtils', () {
    group('addrTagToBase58', () {
      test('should encode test vectors correctly', () {
        for (var vector in testVectors) {
          final tagBytes = Uint8List.fromList(
              List<int>.generate(vector['tag']!.length ~/ 2,
                  (i) => int.parse(vector['tag']!.substring(i * 2, i * 2 + 2), radix: 16)));
          final base58Tag = TagUtils.addrTagToBase58(tagBytes);
          expect(base58Tag, vector['expectedBase58']);
        }
      });

      test('should return null for null input', () {
        expect(TagUtils.addrTagToBase58(null), isNull);
      });

      test('should throw for invalid length', () {
        final invalidTag = Uint8List(10);
        expect(() => TagUtils.addrTagToBase58(invalidTag), throwsArgumentError);
      });

      test('should be consistent for same input', () {
        final tagBytes = Uint8List.fromList(
            List<int>.generate(testVectors[0]['tag']!.length ~/ 2,
                (i) => int.parse(testVectors[0]['tag']!.substring(i * 2, i * 2 + 2), radix: 16)));
        final tag1 = TagUtils.addrTagToBase58(tagBytes);
        final tag2 = TagUtils.addrTagToBase58(tagBytes);
        expect(tag1, tag2);
      });

      test('should produce valid checksum', () {
        final tagBytes = Uint8List.fromList(
            List<int>.generate(testVectors[0]['tag']!.length ~/ 2,
                (i) => int.parse(testVectors[0]['tag']!.substring(i * 2, i * 2 + 2), radix: 16)));
        final base58Tag = TagUtils.addrTagToBase58(tagBytes);
        final decoded = TagUtils.base58ToAddrTag(base58Tag!);

        expect(decoded!.length + 2, 22);
        expect(decoded, tagBytes);
      });
    });

    group('validateBase58Tag', () {
      test('should validate correct tags', () {
        for (var vector in testVectors) {
          final tagBytes = Uint8List.fromList(
              List<int>.generate(vector['tag']!.length ~/ 2,
                  (i) => int.parse(vector['tag']!.substring(i * 2, i * 2 + 2), radix: 16)));
          final base58Tag = TagUtils.addrTagToBase58(tagBytes);
          expect(TagUtils.validateBase58Tag(base58Tag!), isTrue);
        }
      });

      test('should reject invalid length', () {
        final invalidTag = '3vQB7B6MrGQZaxCuFg4oh'; // shorter than 22 bytes decoded
        expect(TagUtils.validateBase58Tag(invalidTag), isFalse);
      });

      test('should reject modified checksum', () {
        final tagBytes = Uint8List.fromList(
            List<int>.generate(testVectors[0]['tag']!.length ~/ 2,
                (i) => int.parse(testVectors[0]['tag']!.substring(i * 2, i * 2 + 2), radix: 16)));
        final base58Tag = TagUtils.addrTagToBase58(tagBytes);

        final corruptTag = base58Tag!.substring(0, base58Tag.length - 1) + 'X';
        expect(TagUtils.validateBase58Tag(corruptTag), isFalse);
      });

      test('should reject invalid base58 characters', () {
        expect(TagUtils.validateBase58Tag('not-base58!'), isFalse);
        expect(TagUtils.validateBase58Tag('0O1Il'), isFalse);
      });

      test('should handle empty string', () {
        expect(TagUtils.validateBase58Tag(''), isFalse);
      });

      test('should handle null input', () {
        expect(() => TagUtils.validateBase58Tag(null as String), throwsA(anything));
      });
    });

    group('base58ToAddrTag', () {
      test('should decode test vectors correctly', () {
        for (var vector in testVectors) {
          final tagBytes = Uint8List.fromList(
              List<int>.generate(vector['tag']!.length ~/ 2,
                  (i) => int.parse(vector['tag']!.substring(i * 2, i * 2 + 2), radix: 16)));
          final base58Tag = TagUtils.addrTagToBase58(tagBytes);
          final decoded = TagUtils.base58ToAddrTag(base58Tag!);

          expect(decoded, isNotNull);
          expect(decoded!.toList(), tagBytes.toList());
        }
      });

      test('should throw for invalid length', () {
        final invalidTag = '3vQB7B6MrGQZaxCuFg4oh'; // shorter than 22 bytes decoded
        expect(() => TagUtils.base58ToAddrTag(invalidTag), throwsArgumentError);
      });

      test('should throw for invalid base58', () {
        expect(() => TagUtils.base58ToAddrTag('not-base58!'), throwsA(anything));
      });

      test('should be reversible', () {
        final tagBytes = Uint8List.fromList(
            List<int>.generate(testVectors[0]['tag']!.length ~/ 2,
                (i) => int.parse(testVectors[0]['tag']!.substring(i * 2, i * 2 + 2), radix: 16)));
        final base58Tag = TagUtils.addrTagToBase58(tagBytes);
        final decoded = TagUtils.base58ToAddrTag(base58Tag!);
        final reEncoded = TagUtils.addrTagToBase58(decoded!);

        expect(reEncoded, base58Tag);
      });

      test('should handle empty string', () {
        expect(() => TagUtils.base58ToAddrTag(''), throwsA(anything));
      });

      test('should handle null input', () {
        expect(() => TagUtils.base58ToAddrTag(null as String), throwsA(anything));
      });
    });
  });
}
