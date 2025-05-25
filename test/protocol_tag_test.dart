import 'package:test/test.dart';
import 'dart:typed_data';
import 'package:mochimo_wots/core/protocol/tags.dart'; 
import 'package:mochimo_wots/core/utils/byte_utils.dart'; 

void main() {
  group('Tag', () {
    group('validation', () {
      test('should validate tag length', () {
        final shortTag = Uint8List(11);
        final longTag = Uint8List(13);
        final validTag = Uint8List(12)..fillRange(0, 12, 0x41); // Fill with 0x41

        expect(Tag.isValid(shortTag), isFalse);
        expect(Tag.isValid(longTag), isFalse);
        expect(Tag.isValid(validTag), isTrue);
      });

      test('should validate null tag', () {
        // In Dart, `null as any` and `undefined as any` both translate to `null`.
        expect(Tag.isValid(null), isFalse);
      });

      test('should handle zero tag', () {
        final zeroTag = Uint8List(12); // Defaults to all zeros
        expect(Tag.isZero(zeroTag), isTrue);

        zeroTag[0] = 1; // Change one byte
        expect(Tag.isZero(zeroTag), isFalse);
      });
    });

    group('extraction', () {
      test('should extract tag from address', () {
        final address = Uint8List(2208);
        final expectedTag = Uint8List(12)..fillRange(0, 12, 0x41); // Fill with 0x41
        address.setAll(address.length - Tag.TAG_LENGTH, expectedTag);

        final extractedTag = Tag.getTag(address);
        expect(ByteUtils.compareBytes(extractedTag, expectedTag), isTrue);
      });

      test('should throw on invalid address length', () {
        final invalidAddress = Uint8List(100);
        expect(
          () => Tag.getTag(invalidAddress),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid address length: 100. Expected 2208.',
          )),
        );
      });

      test('should handle 12-byte tag boundary correctly', () {
        final address = Uint8List(2208);
        final expectedTag = Uint8List(12);
        for (int i = 0; i < 12; i++) {
          expectedTag[i] = i;
        }
        address.setAll(2208 - 12, expectedTag);
        
        final extractedTag = Tag.getTag(address);
        expect(extractedTag.length, equals(12));
        for (int i = 0; i < 12; i++) {
          expect(extractedTag[i], equals(i));
        }
      });

      test('should preserve all 12 bytes of tag data', () {
        final address = Uint8List(2208);
        final expectedTag = Uint8List(12);
        for (int i = 0; i < 12; i++) {
          expectedTag[i] = 255 - i; // Use distinct values
        }
        address.setAll(2208 - Tag.TAG_LENGTH, expectedTag);
        
        final extractedTag = Tag.getTag(address);
        expect(extractedTag.length, equals(12));
        for (int i = 0; i < 12; i++) {
          expect(extractedTag[i], equals(255 - i));
        }
      });
    });

    group('tagging', () {
      test('should create new instance', () {
        final address = Uint8List(2208);
        final tag = Uint8List(12)..fillRange(0, 12, 0x41); // Fill with 0x41

        final tagged = Tag.tag(address, tag);
        expect(tagged, isNot(equals(address))); // Check if it's a new instance
        expect(tagged.length, address.length);

        final extractedTag = Tag.getTag(tagged);
        expect(ByteUtils.compareBytes(extractedTag, tag), isTrue);
      });

      test('should handle address with existing tag', () {
        final address = Uint8List(2208);
        final oldTag = Uint8List(12)..fillRange(0, 12, 0x41); // Fill with 0x41
        final newTag = Uint8List(12)..fillRange(0, 12, 0x43); // Fill with 0x43

        final tagged1 = Tag.tag(address, oldTag);
        expect(ByteUtils.compareBytes(Tag.getTag(tagged1), oldTag), isTrue);

        final tagged2 = Tag.tag(tagged1, newTag);
        expect(ByteUtils.compareBytes(Tag.getTag(tagged2), newTag), isTrue);
      });
    });
  });
}