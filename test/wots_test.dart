import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mochimo_wots/core/hasher/mochimo_hasher.dart';
import 'package:mochimo_wots/core/protocol/wots.dart';
import 'package:mochimo_wots/core/protocol/tags.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';

void main() {
  group('WOTS Protocol', () {
    group('constants', () {
      test('should have correct WOTS parameters', () {
        expect(WOTS.WOTSW, 16);
        expect(WOTS.WOTSLOGW, 4);
        expect(WOTS.PARAMSN, 32);
        expect(WOTS.WOTSLEN1, 64);
        expect(WOTS.WOTSLEN2, 3);
        expect(WOTS.WOTSLEN, 67);
        expect(WOTS.WOTSSIGBYTES, 2144);
        expect(WOTS.TXSIGLEN, 2144);
      });
    });

    group('address generation and validation', () {
      void mockRandomBytes(Uint8List bytes) {
        for (int i = 0; i < bytes.length; i++) {
          bytes[i] = 0x42;
        }
      }

      test('should generate valid address', () {
        final secret = Uint8List(32)..fillRange(0, 32, 0x12);
        final address = WOTS.generateRandomAddress(null, secret);

        expect(address.length, 2208);
        expect(WOTS.isValid(secret, address, mockRandomBytes), isTrue);
      });

      test('should generate valid tagged address', () {
        final secret = Uint8List(32)..fillRange(0, 32, 0x12);
        final tag = Uint8List(12)..fillRange(0, 12, 0x34);
        final address = WOTS.generateRandomAddress(tag, secret);

        expect(address.length, 2208);
        expect(WOTS.isValid(secret, address, mockRandomBytes), isTrue);
      });

      test('should throw on invalid secret length', () {
        final secret = Uint8List(31);
        expect(
            () => WOTS.generateRandomAddress(null, secret),
            throwsA(predicate((e) =>
                e is ArgumentError &&
                e.message.contains('Invalid secret length'))));
      });

      test('should throw on invalid tag length', () {
        final secret = Uint8List(32);
        final tag = Uint8List(11);
        expect(
            () => WOTS.generateRandomAddress(tag, secret),
            throwsA(predicate((e) =>
                e is ArgumentError &&
                e.message.contains('Invalid tag length'))));
      });
    });

    group('address splitting', () {
      test('should split address correctly', () {
        final address = Uint8List(2208);
        address.fillRange(0, 2144, 0x11);
        address.fillRange(2144, 2176, 0x22);
        address.fillRange(2176, 2208, 0x33);

        final pk = Uint8List(2144);
        final pubSeed = Uint8List(32);
        final rnd2 = Uint8List(32);
        final tag = Uint8List(12);

        WOTS.splitAddress(address, pk, pubSeed, rnd2, tag);

        expect(pk.every((b) => b == 0x11), isTrue);
        expect(pubSeed.every((b) => b == 0x22), isTrue);
        expect(rnd2.every((b) => b == 0x33), isTrue);
        expect(tag.every((b) => b == 0x33), isTrue);
      });

      test('should handle null tag', () {
        final address = Uint8List(2208);
        final pk = Uint8List(2144);
        final pubSeed = Uint8List(32);
        final rnd2 = Uint8List(32);

        expect(() => WOTS.splitAddress(address, pk, pubSeed, rnd2, null),
            returnsNormally);
      });

      test('should throw on invalid component lengths', () {
        final address = Uint8List(2208);
        final pk = Uint8List(2143);
        final pubSeed = Uint8List(32);
        final rnd2 = Uint8List(32);

        expect(
            () => WOTS.splitAddress(address, pk, pubSeed, rnd2, null),
            throwsA(predicate((e) =>
                e is ArgumentError &&
                e.message.contains('Invalid pk length'))));
      });
    });

    group('signing and verification', () {
      test('should verify valid signature', () {
        final secret = Uint8List(32)..fillRange(0, 32, 0x12);
        final msg = Uint8List(32)..fillRange(0, 32, 0x34);
        final pubSeed = Uint8List(32)..fillRange(0, 32, 0x56);
        final addr = Uint8List(32)..fillRange(0, 32, 0x78);

        final sig = Uint8List(WOTS.WOTSSIGBYTES);
        WOTS.wotsSign(sig, msg, secret, pubSeed, 0, addr);

        final pk = Uint8List(WOTS.WOTSSIGBYTES);
        WOTS.wotsPkgen(pk, secret, pubSeed, 0, addr);

        final computedPk = WOTS.wotsPkFromSig(sig, msg, pubSeed, addr);
        expect(computedPk, pk);
      });

      test('should fail on modified message', () {
        final secret = Uint8List(32)..fillRange(0, 32, 0x12);
        final msg = Uint8List(32)..fillRange(0, 32, 0x34);
        final pubSeed = Uint8List(32)..fillRange(0, 32, 0x56);
        final addr = Uint8List(32)..fillRange(0, 32, 0x78);

        final sig = Uint8List(WOTS.WOTSSIGBYTES);
        WOTS.wotsSign(sig, msg, secret, pubSeed, 0, addr);

        final pk = Uint8List(WOTS.WOTSSIGBYTES);
        WOTS.wotsPkgen(pk, secret, pubSeed, 0, addr);

        msg[0] ^= 1;

        final computedPk = WOTS.wotsPkFromSig(sig, msg, pubSeed, addr);
        expect(computedPk, isNot(pk));
      });
    });

    group('chain operations', () {
      test('should generate correct chain length', () {
        final msg = Uint8List(32)..fillRange(0, 32, 0x12);
        final lengths = List<int>.filled(WOTS.WOTSLEN, 0);

        WOTS.chainLengths(msg, lengths);

        expect(lengths.length, WOTS.WOTSLEN);
        for (int i = 0; i < WOTS.WOTSLEN1; i++) {
          expect(lengths[i], inInclusiveRange(0, 15));
        }
        for (int i = WOTS.WOTSLEN1; i < WOTS.WOTSLEN; i++) {
          expect(lengths[i], inInclusiveRange(0, 15));
        }
      });

      test('should handle zero message', () {
        final msg = Uint8List(32);
        final lengths = List<int>.filled(WOTS.WOTSLEN, 0);

        WOTS.chainLengths(msg, lengths);

        for (int i = 0; i < WOTS.WOTSLEN1; i++) {
          expect(lengths[i], 0);
        }
      });
    });

    group('base-w operations', () {
      test('should convert bytes to base-w representation', () {
        final msg = Uint8List.fromList([0x12, 0x34]);
        final destination = List<int>.filled(4, 0);

        WOTS.baseW_(msg, destination, 0, 4);

        expect(destination, [1, 2, 3, 4]);
      });

      test('should handle offset correctly', () {
        final msg = Uint8List.fromList([0x12, 0x34]);
        final destination = List<int>.filled(6, -1);

        WOTS.baseW_(msg, destination, 2, 4);

        expect(destination, [-1, -1, 1, 2, 3, 4]);
      });
    });

    group('checksum operations', () {
      test('should compute correct checksum', () {
        final msgBaseW = List<int>.filled(WOTS.WOTSLEN, 0);
        msgBaseW[0] = 5;

        WOTS.wotsChecksum(msgBaseW, WOTS.WOTSLEN1);

        final checksumPart = msgBaseW.sublist(WOTS.WOTSLEN1);
        expect(checksumPart.length, WOTS.WOTSLEN2);
        expect(checksumPart.any((v) => v != 0), isTrue);
      });

      test('should handle all max values', () {
        final msgBaseW = List<int>.filled(WOTS.WOTSLEN, 0);
        for (int i = 0; i < WOTS.WOTSLEN1; i++) {
          msgBaseW[i] = 15;
        }

        WOTS.wotsChecksum(msgBaseW, WOTS.WOTSLEN1);

        final checksumPart = msgBaseW.sublist(WOTS.WOTSLEN1);
        expect(checksumPart.every((v) => v == 0), isTrue);
      });
    });

    group('seed expansion', () {
      test('should expand seed to correct length', () {
        final seed = Uint8List(32)..fillRange(0, 32, 0x12);
        final expanded = Uint8List(WOTS.WOTSSIGBYTES);

        WOTS.expandSeed(expanded, seed);

        expect(expanded.length, WOTS.WOTSSIGBYTES);
        expect(expanded.any((b) => b != 0), isTrue);
      });

      test('should be deterministic', () {
        final seed = Uint8List(32)..fillRange(0, 32, 0x12);
        final expanded1 = Uint8List(WOTS.WOTSSIGBYTES);
        final expanded2 = Uint8List(WOTS.WOTSSIGBYTES);

        WOTS.expandSeed(expanded1, seed);
        WOTS.expandSeed(expanded2, seed);

        expect(expanded1, expanded2);
      });
    });

    group('end-to-end operations', () {
      test('should verify signature with multiple updates', () {
        final secret = Uint8List(32)..fillRange(0, 32, 0x12);
        final msg = Uint8List(32)..fillRange(0, 32, 0x34);
        final pubSeed = Uint8List(32)..fillRange(0, 32, 0x56);
        final addr = Uint8List(32)..fillRange(0, 32, 0x78);

        final pk = Uint8List(WOTS.WOTSSIGBYTES);
        WOTS.wotsPkgen(pk, secret, pubSeed, 0, addr);

        final sig1 = Uint8List(WOTS.WOTSSIGBYTES);
        WOTS.wotsSign(sig1, msg, secret, pubSeed, 0, addr);
        final pk1 = WOTS.wotsPkFromSig(sig1, msg, pubSeed, addr);

        msg[0] ^= 1;
        final sig2 = Uint8List(WOTS.WOTSSIGBYTES);
        WOTS.wotsSign(sig2, msg, secret, pubSeed, 0, addr);
        final pk2 = WOTS.wotsPkFromSig(sig2, msg, pubSeed, addr);

        expect(sig1, isNot(sig2));
        expect(pk1, pk);
        expect(pk2, pk);
      });
    });
  });
}
