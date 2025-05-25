import 'package:test/test.dart';
import 'dart:typed_data';
import 'package:mochimo_wots/core/model/byte_buffer.dart';
import 'package:mochimo_wots/core/protocol/wots_hash.dart';

void main() {
  group('WOTSHash', () {
    group('constants', () {
      test('should have correct padding values', () {
        expect(WOTSHash.XMSS_HASH_PADDING_F, equals(0));
        expect(WOTSHash.XMSS_HASH_PADDING_PRF, equals(3));
      });
    });

    group('address manipulation', () {
      late ByteBuffer addr;

      setUp(() {
        addr = ByteBuffer.allocate(32); // Allocate a 32-byte buffer
      });

      test('should set chain address correctly', () {
        WOTSHash.setChainAddr(addr, 0x12345678);
        addr.position(20); // Reset position to read from where it was written
      
        expect(addr.get_(), equals(0x12));
        expect(addr.get_(), equals(0x34));
        expect(addr.get_(), equals(0x56));
        expect(addr.get_(), equals(0x78));
      });

      test('should set hash address correctly', () {
        WOTSHash.setHashAddr(addr, 0x12345678);
        addr.position(24); // Reset position to read from where it was written
        expect(addr.get_(), equals(0x12));
        expect(addr.get_(), equals(0x34));
        expect(addr.get_(), equals(0x56));
        expect(addr.get_(), equals(0x78));
      });

      test('should set key and mask correctly', () {
        WOTSHash.setKeyAndMask(addr, 0x12345678);
        addr.position(28); // Reset position to read from where it was written
        expect(addr.get_(), equals(0x12));
        expect(addr.get_(), equals(0x34));
        expect(addr.get_(), equals(0x56));
        expect(addr.get_(), equals(0x78));
      });
    });

  });


   group('addrToBytes', () {
      test('should convert address to little-endian bytes', () {
        final addr = ByteBuffer.allocate(32);
        // putInt in ByteBuffer writes in Big-Endian by default.
        // So, 0x12345678 will be stored as [0x12, 0x34, 0x56, 0x78] in the buffer.
        addr.putInt(0x12345678);
        addr.position(4); // Move position to write another int
        addr.putInt(0x9ABCDEF0);
        addr.position(0); // Reset position for addrToBytes

        final bytes = WOTSHash.addrToBytes(addr);

        // addrToBytes should convert the big-endian representation in ByteBuffer
        // to little-endian in the output ByteArray.
        // So, 0x12345678 (BE) becomes 0x78563412 (LE)
        // and 0x9ABCDEF0 (BE) becomes 0xF0DEBC9A (LE)
        expect(bytes[0], equals(0x78));
        expect(bytes[1], equals(0x56));
        expect(bytes[2], equals(0x34));
        expect(bytes[3], equals(0x12));
        expect(bytes[4], equals(0xF0));
        expect(bytes[5], equals(0xDE));
        expect(bytes[6], equals(0xBC));
        expect(bytes[7], equals(0x9A));
      });
    });

        group('prf', () {
      test('should generate deterministic output', () {
        final out1 = Uint8List(32);
        final out2 = Uint8List(32);
        final input = Uint8List(32)..fillRange(0, 32, 0x12);
        final key = Uint8List(32)..fillRange(0, 32, 0x34);

        WOTSHash.prf(out1, 0, input, key);
        WOTSHash.prf(out2, 0, input, key);

        expect(out1, equals(out2));
        expect(out1.any((b) => b != 0), isTrue); // Should not be all zeros
      });

      test('should respect output offset', () {
        final out = Uint8List(64)..fillRange(0, 64, 0xFF);
        final input = Uint8List(32)..fillRange(0, 32, 0x12);
        final key = Uint8List(32)..fillRange(0, 32, 0x34);

        WOTSHash.prf(out, 16, input, key);

        // First 16 bytes should be unchanged
        for (int i = 0; i < 16; i++) {
          expect(out[i], equals(0xFF));
        }
        // Next 32 bytes should be hash output
        expect(out.sublist(16, 48).any((b) => b != 0xFF), isTrue);
        // Last 16 bytes should be unchanged
        for (int i = 48; i < 64; i++) {
          expect(out[i], equals(0xFF));
        }
      });
    });



      group('thashF', () {
      test('should generate deterministic output', () {
        final out1 = Uint8List(32);
        final out2 = Uint8List(32);
        final input = Uint8List(32)..fillRange(0, 32, 0x12);
        final pubSeed = Uint8List(32)..fillRange(0, 32, 0x34);
        final addr = ByteBuffer.allocate(32);

        WOTSHash.thashF(out1, 0, input, 0, pubSeed, addr);
        WOTSHash.thashF(out2, 0, input, 0, pubSeed, addr);

        expect(out1, equals(out2));
        expect(out1.any((b) => b != 0), isTrue); // Should not be all zeros
      });

      test('should produce different outputs for different addresses', () {
        final out1 = Uint8List(32);
        final out2 = Uint8List(32);
        final input = Uint8List(32)..fillRange(0, 32, 0x12);
        final pubSeed = Uint8List(32)..fillRange(0, 32, 0x34);
        final addr1 = ByteBuffer.allocate(32);
        final addr2 = ByteBuffer.allocate(32);
        addr2.putInt(1); // Make addr2 different from addr1

        WOTSHash.thashF(out1, 0, input, 0, pubSeed, addr1);
        WOTSHash.thashF(out2, 0, input, 0, pubSeed, addr2);

        expect(out1, isNot(equals(out2)));
      });

      test('should respect input and output offsets', () {
        final out = Uint8List(64)..fillRange(0, 64, 0xFF);
        final input = Uint8List(64)..fillRange(0, 64, 0x12);
        final pubSeed = Uint8List(32)..fillRange(0, 32, 0x34);
        final addr = ByteBuffer.allocate(32);

        WOTSHash.thashF(out, 16, input, 8, pubSeed, addr);

        // First 16 bytes should be unchanged
        for (int i = 0; i < 16; i++) {
          expect(out[i], equals(0xFF));
        }
        // Next 32 bytes should be hash output
        expect(out.sublist(16, 48).any((b) => b != 0xFF), isTrue);
        // Last 16 bytes should be unchanged
        for (int i = 48; i < 64; i++) {
          expect(out[i], equals(0xFF));
        }
      });
    });






}