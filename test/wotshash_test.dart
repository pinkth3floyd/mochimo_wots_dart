import 'package:test/test.dart';
import 'dart:typed_data';
import 'package:mochimo_wots/core/model/ByteBuffer.dart'; 
import 'package:mochimo_wots/core/hasher/MochimoHasher.dart';
import 'package:mochimo_wots/core/protocol/WotsHash.dart'; 

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
}