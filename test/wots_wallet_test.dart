import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mochimo_wots/core/protocol/WotsWallet.dart';
import 'package:mochimo_wots/core/utils/ByteUtils.dart';
import 'package:mochimo_wots/core/protocol/Wots.dart';
import 'package:mochimo_wots/core/utils/TagUtils.dart';
import 'package:mochimo_wots/core/utils/CRC16.dart';
import 'package:mochimo_wots/core/protocol/WotsAddress.dart';

void main() {
  late Uint8List testSecret;
  late Uint8List testTag;
  late WOTSWallet wallet;

  void mockRandomGenerator(Uint8List bytes) {
    bytes.fillRange(0, bytes.length, 0x42);
  }

  setUp(() {
    testSecret = Uint8List(32)..fillRange(0, 32, 0x12);
    testTag = Uint8List(12)..fillRange(0, 12, 0x34);
  });

  group('WOTSWallet', () {
    test('should create wallet with valid parameters', () {
      wallet = WOTSWallet.create('test_wallet', testSecret, testTag, mockRandomGenerator);
      expect(wallet.getName(), equals('test_wallet'));
      expect(wallet.getSecret()?.length, equals(32));
      expect(wallet.getWots()?.length, equals(2208));
      expect(wallet.getAddrTag()?.length, equals(12));
    });

    test('should throw on invalid secret length', () {
      final invalidSecret = Uint8List(16)..fillRange(0, 16, 0x12);
      expect(
        () => WOTSWallet.create('test_wallet', invalidSecret),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Invalid secret length',
        )),
      );
    });

    test('should generate valid address components', () {
      wallet = WOTSWallet.create('test_wallet', testSecret, testTag, mockRandomGenerator);
      
      final wotsPk = wallet.getWotsPk();
      final pubSeed = wallet.getWotsPubSeed();
      final adrs = wallet.getWotsAdrs();
      final tag = wallet.getWotsTag();
      
      expect(wotsPk?.length, equals(2144));
      expect(pubSeed?.length, equals(32));
      expect(adrs?.length, equals(32));
      expect(tag?.length, equals(12));
    });

    test('should handle address tag operations', () {
      wallet = WOTSWallet.create('test_wallet', testSecret, testTag, mockRandomGenerator);
      
      final addrTag = wallet.getAddrTag();
      final addrTagHex = wallet.getAddrTagHex();
      final addrTagBase58 = wallet.getAddrTagBase58();
      
      expect(addrTag?.length, equals(12));
      expect(addrTagHex?.length, equals(24)); // 12 bytes = 24 hex chars
      expect(addrTagBase58, isNotNull);
    });

    test('should handle WOTS operations', () {
      wallet = WOTSWallet.create('test_wallet', testSecret, testTag, mockRandomGenerator);
      
      final wots = wallet.getWots();
      final wotsHex = wallet.getWotsHex();
      final address = wallet.getAddress();
      final addrHash = wallet.getAddrHash();
      
      expect(wots?.length, equals(2208));
      expect(wotsHex?.length, equals(4416)); // 2208 bytes = 4416 hex chars
      expect(address?.length, equals(40));
      expect(addrHash?.length, equals(28)); // Updated: TXADDRLEN - ADDR_TAG_LEN = 28
    });

    test('should sign and verify messages', () {
      wallet = WOTSWallet.create('test_wallet', testSecret, testTag, mockRandomGenerator);
      
      // Create a 32-byte message for signing (PARAMSN length)
      final message = Uint8List(32)..fillRange(0, 32, 0x01);
      final signature = wallet.sign(message);
      
      expect(signature.length, equals(2144));
      expect(wallet.verify(message, signature), isTrue);
      
      // Test with modified message
      final modifiedMessage = Uint8List(32)..fillRange(0, 32, 0x02);
      expect(wallet.verify(modifiedMessage, signature), isFalse);
    });

    test('should throw on signing without secret', () {
      wallet = WOTSWallet(
        name: 'test_wallet',
        wots: Uint8List(2208)..fillRange(0, 2208, 0x42),
        addrTag: testTag,
      );
      
      final message = Uint8List(32)..fillRange(0, 32, 0x01);
      expect(
        () => wallet.sign(message),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'Cannot sign without secret key or address',
        )),
      );
    });

    test('should throw on verification without public key', () {
      wallet = WOTSWallet(
        name: 'test_wallet',
        secret: testSecret,
        addrTag: testTag,
      );
      
      final message = Uint8List(32)..fillRange(0, 32, 0x01);
      final signature = Uint8List(2144);
      expect(
        () => wallet.verify(message, signature),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'Cannot verify without public key (address)',
        )),
      );
    });

    test('should handle clear operation', () {
      wallet = WOTSWallet.create('test_wallet', testSecret, testTag, mockRandomGenerator);
      
      // Verify wallet has data before clearing
      expect(wallet.getSecret(), isNotNull);
      expect(wallet.getWots(), isNotNull);
      expect(wallet.getAddrTag(), isNotNull);
      expect(wallet.getAddrTagHex(), isNotNull);
      expect(wallet.getWotsHex(), isNotNull);
      
      wallet.clear();
      
      // Check if the wallet properties are nullified
      expect(wallet.getSecret(), isNull);
      expect(wallet.getWots(), isNull);
      expect(wallet.getAddrTag(), isNull);
      expect(wallet.getAddrTagHex(), isNull);
      expect(wallet.getWotsHex(), isNull);
      expect(wallet.toString(), equals('Empty address'));
    });

    test('should convert to string correctly', () {
      wallet = WOTSWallet.create('test_wallet', testSecret, testTag, mockRandomGenerator);
      final str = wallet.toString();
      expect(str, matches(RegExp(r'^[0-9a-fA-F]{32}\.\.\.[0-9a-fA-F]{24}$')));
      
      // Test empty wallet
      final emptyWallet = WOTSWallet(name: 'empty');
      expect(emptyWallet.toString(), equals('Empty address'));
      
      // Test tag-only wallet
      final tagOnlyWallet = WOTSWallet(name: 'tag_only', addrTag: testTag);
      expect(tagOnlyWallet.toString(), startsWith('tag-'));
    });

    test('should convert to JSON correctly', () {
      wallet = WOTSWallet.create('test_wallet', testSecret, testTag, mockRandomGenerator);
      final json = wallet.toJson();
      
      expect(json['name'], equals('test_wallet'));
      expect(json['wots'], isNotNull);
      expect(json['addrTag'], isNotNull);
      expect(json['secret'], isNotNull);
      expect(json['addrTagHex'], isNotNull);
      expect(json['wotsAddrHex'], isNotNull);
    });
  });
}
