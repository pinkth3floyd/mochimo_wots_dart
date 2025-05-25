import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mochimo_wots/core/utils/tag_utils.dart';

void main() {
  test('DEBUG - Print actual Base58 encoding', () {
    final tagHex = '3f1fba7025c7d37470e700';
    final tagBytes = Uint8List.fromList(
      List<int>.generate(
        12,
        (i) => int.parse(
          tagHex.padRight(24, '0').substring(i * 2, i * 2 + 2),
          radix: 16,
        ),
      ),
    );
    final base58Tag = TagUtils.addrTagToBase58(tagBytes);
    print('Actual Base58 encoding for $tagHex: $base58Tag');

    // Also test the zero case
    final zeroTagBytes = Uint8List(12);
    final zeroBase58Tag = TagUtils.addrTagToBase58(zeroTagBytes);
    print('Actual Base58 encoding for all zeros: $zeroBase58Tag');
  });

  final testVectors = [
    {
      'tag': '3f1fba7025c7d37470e700', // 12 bytes = 24 hex chars
      'expectedBase58': 'QCygktKEdEEJTrMjpTx',
    },
    {
      'tag': '000000000000000000000000', // 12 bytes = 24 hex chars
      'expectedBase58':
          '11111111111111', // 14 ones for 12 zero bytes + 2 checksum bytes
    },
  ];

  Uint8List hexToBytes(String hex) {
    final paddedHex = hex.padRight(24, '0');
    return Uint8List.fromList(
      List<int>.generate(
        12,
        (i) => int.parse(
          paddedHex.substring(i * 2, i * 2 + 2),
          radix: 16,
        ),
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

        expect(decoded!.length, 12);
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
        expect(
          () => TagUtils.validateBase58Tag(null as String),
          throwsA(anything),
        );
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

      test('should handle null input', () {
        expect(
          () => TagUtils.base58ToAddrTag(null as String),
          throwsA(anything),
        );
      });
    });
  });
}
