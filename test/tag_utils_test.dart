import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mochimo_wots/core/utils/tag_utils.dart';

void main() {
  final testVectors = [
    {
      'tag': '9f810c2447a76e93b17ebff96c0b29952e4355f1',
      'expectedBase58': 'kHtV35ttVpyiH42FePCiHo2iFmcJS3',
    },
    {
      'tag': '0000000000000000000000000000000000000000',
      'expectedBase58': '1111111111111111111111',
    },
  ];

  Uint8List hexToBytes(String hex) {
    return Uint8List.fromList(
      List<int>.generate(
        20,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  group('TagUtils', () {
    group('addrTagToBase58', () {
      test('should encode test vectors correctly', () {
        for (var vector in testVectors) {
          final tagBytes = hexToBytes(vector['tag']!);
          final base58Tag = TagUtils.addrTagToBase58(tagBytes);
          expect(base58Tag, vector['expectedBase58'],
              reason: 'Failed for tag: ${vector['tag']}');
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
        final tagBytes = hexToBytes(testVectors[0]['tag']!);
        final tag1 = TagUtils.addrTagToBase58(tagBytes);
        final tag2 = TagUtils.addrTagToBase58(tagBytes);
        expect(tag1, tag2);
      });

      test('should produce valid checksum', () {
        final tagBytes = hexToBytes(testVectors[0]['tag']!);
        final base58Tag = TagUtils.addrTagToBase58(tagBytes);
        final decoded = TagUtils.base58ToAddrTag(base58Tag!);

        expect(decoded!.length, 20);
        expect(decoded, tagBytes);
      });
    });

    group('validateBase58Tag', () {
      test('should validate correct tags', () {
        for (var vector in testVectors) {
          final tagBytes = hexToBytes(vector['tag']!);
          final base58Tag = TagUtils.addrTagToBase58(tagBytes);
          expect(TagUtils.validateBase58Tag(base58Tag!), isTrue);
        }
      });

      test('should reject invalid length', () {
        final invalidTag = '3vQB7B6MrGQZaxC'; // shorter than 14 bytes decoded
        expect(TagUtils.validateBase58Tag(invalidTag), isFalse);
      });

      test('should reject modified checksum', () {
        final tagBytes = hexToBytes(testVectors[0]['tag']!);
        final base58Tag = TagUtils.addrTagToBase58(tagBytes);

        final corruptTag = '${base58Tag!.substring(0, base58Tag.length - 1)}X';
        expect(TagUtils.validateBase58Tag(corruptTag), isFalse);
      });

      test('should reject invalid base58 characters', () {
        expect(TagUtils.validateBase58Tag('not-base58!'), isFalse);
        expect(TagUtils.validateBase58Tag('0O1Il'), isFalse);
      });

      test('should handle empty string', () {
        expect(TagUtils.validateBase58Tag(''), isFalse);
      });
    });

    group('base58ToAddrTag', () {
      test('should decode test vectors correctly', () {
        for (var vector in testVectors) {
          final tagBytes = hexToBytes(vector['tag']!);
          final base58Tag = TagUtils.addrTagToBase58(tagBytes);
          final decoded = TagUtils.base58ToAddrTag(base58Tag!);

          expect(decoded, isNotNull);
          expect(decoded!.toList(), tagBytes.toList());
        }
      });

      test('should throw for invalid length', () {
        final invalidTag = '3vQB7B6MrGQZaxC'; // shorter than 14 bytes decoded
        expect(() => TagUtils.base58ToAddrTag(invalidTag), throwsArgumentError);
      });

      test('should throw for invalid base58', () {
        expect(
          () => TagUtils.base58ToAddrTag('not-base58!'),
          throwsA(anything),
        );
      });

      test('should be reversible', () {
        final tagBytes = hexToBytes(testVectors[0]['tag']!);
        final base58Tag = TagUtils.addrTagToBase58(tagBytes);
        final decoded = TagUtils.base58ToAddrTag(base58Tag!);
        final reEncoded = TagUtils.addrTagToBase58(decoded!);

        expect(reEncoded, base58Tag);
      });

      test('should handle empty string', () {
        expect(() => TagUtils.base58ToAddrTag(''), throwsA(anything));
      });
    });
  });
}
