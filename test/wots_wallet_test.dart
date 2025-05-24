import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mochimo_wots/core/protocol/WotsWallet.dart';
import 'package:mochimo_wots/core/utils/ByteUtils.dart';
import 'package:mochimo_wots/core/protocol/Wots.dart';
import 'package:mochimo_wots/core/utils/TagUtils.dart';
import 'package:mochimo_wots/core/utils/CRC16.dart';
import 'package:mochimo_wots/core/protocol/WotsAddress.dart';

void main() {
  group('WOTSWallet', () {
    void mockRandomBytes(Uint8List bytes) {
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = 0x42;
      }
    }

    test('should handle 12-byte tag correctly', () {
      final secret = Uint8List(32)..fillRange(0, 32, 0x12);
      final tag = Uint8List(12)..fillRange(0, 12, 0x34);
      
      final wallet = WOTSWallet.create('test_wallet', secret, tag, mockRandomBytes);
      expect(wallet.getAddrTag()?.length, equals(12));
      
      // Verify tag content
      final retrievedTag = wallet.getAddrTag();
      expect(retrievedTag, isNotNull);
      for (int i = 0; i < 12; i++) {
        expect(retrievedTag![i], equals(0x34));
      }
    });

    test('should reject invalid tag length', () {
      final secret = Uint8List(32)..fillRange(0, 32, 0x12);
      final invalidTag = Uint8List(20)..fillRange(0, 20, 0x34); // Using old 20-byte length
      
      expect(
        () => WOTSWallet(
          name: 'test_wallet',
          secret: secret,
          addrTag: invalidTag,
        ),
        throwsA(predicate((e) => e is ArgumentError && e.message.contains('Invalid address tag'))),
      );
    });

    test('should handle tag extraction from address', () {
      final secret = Uint8List(32)..fillRange(0, 32, 0x12);
      final wallet = WOTSWallet.create('test_wallet', secret, null, mockRandomBytes);
      
      final extractedTag = wallet.getAddrTag();
      expect(extractedTag?.length, equals(WotsAddress.ADDR_TAG_LEN));
    });
  });
}
