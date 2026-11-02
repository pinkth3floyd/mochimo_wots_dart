import 'dart:typed_data';

import 'package:mochimo_wots/core/hasher/mochimo_hasher.dart';
import 'package:mochimo_wots/core/protocol/wots.dart';
import 'package:mochimo_wots/core/protocol/wots_hash.dart';
import 'package:test/test.dart';

/// Independent copy of the buffer built by `prf()` and `expand_seed()` in
/// `src/wots.c`. This does not call [WOTSHash.prf], so a layout drift fails.
Uint8List cPrf(Uint8List input, Uint8List key) {
  final buf = Uint8List(96);
  buf[31] = WOTSHash.XMSS_HASH_PADDING_PRF;
  buf.setRange(32, 64, key);
  buf.setRange(64, 96, input);
  return MochimoHasher.hash(buf);
}

void main() {
  group('Mochimo wots.c layout', () {
    test('expandSeed places the counter in the last four bytes', () {
      final seed = Uint8List(32)..fillRange(0, 32, 0x42);
      final expanded = Uint8List(WOTS.WOTSSIGBYTES);
      WOTS.expandSeed(expanded, seed);

      for (var i = 0; i < 3; i++) {
        final ctr = Uint8List(32);
        ByteData.sublistView(ctr).setUint32(28, i, Endian.big);
        expect(expanded.sublist(i * 32, (i + 1) * 32), cPrf(ctr, seed));
      }
    });

    test('address words are a little-endian cast written big-endian', () {
      final seed = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final buffer = WOTS.addressBuffer(seed);
      WOTSHash.setChainAddr(buffer, 7);
      WOTSHash.setHashAddr(buffer, 3);
      WOTSHash.setKeyAndMask(buffer, 1);
      final bytes = WOTSHash.addrToBytes(buffer);

      // Bytes 00 01 02 03 as a little-endian word are 0x03020100.
      expect(bytes.sublist(0, 4), [0x03, 0x02, 0x01, 0x00]);
      expect(bytes.sublist(20, 24), [0x00, 0x00, 0x00, 0x07]);
      expect(bytes.sublist(24, 28), [0x00, 0x00, 0x00, 0x03]);
      expect(bytes.sublist(28, 32), [0x00, 0x00, 0x00, 0x01]);
    });

    test('published address suffix matches put32 in tx.c', () {
      final address = Uint8List(32);
      WOTS.stampAddressSuffix(address);
      expect(address.sublist(20, 24), [0x42, 0x00, 0x00, 0x00]);
      expect(address.sublist(24, 28), [0x0e, 0x00, 0x00, 0x00]);
      expect(address.sublist(28, 32), [0x01, 0x00, 0x00, 0x00]);
    });

    test('a signature verifies against the same public key', () {
      final secret = Uint8List(32)..fillRange(0, 32, 0x11);
      final pubSeed = Uint8List(32)..fillRange(0, 32, 0x22);
      final addr = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      final msg = Uint8List(32)..fillRange(0, 32, 0x33);

      final pk = Uint8List(WOTS.WOTSSIGBYTES);
      WOTS.wotsPkgen(pk, secret, pubSeed, 0, addr);
      final sig = Uint8List(WOTS.WOTSSIGBYTES);
      WOTS.wotsSign(sig, msg, secret, pubSeed, 0, addr);

      expect(WOTS.wotsPkFromSig(sig, msg, pubSeed, addr), pk);
      expect(pk.any((b) => b != 0), isTrue);
    });
  });
}
