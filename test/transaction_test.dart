import 'dart:typed_data';

import 'package:mochimo_wots/mochimo_wots.dart';
import 'package:test/test.dart';

void main() {
  group('transaction references', () {
    test('accepts the node examples and rejects the invalid ones', () {
      expect(
          TxDestination.isValidReference(TxDestination.encodeMemo('AB-00-EF')),
          isTrue);
      expect(
          TxDestination.isValidReference(
              TxDestination.encodeMemo('123-CDE-789')),
          isTrue);
      expect(TxDestination.isValidReference(TxDestination.encodeMemo('ABC')),
          isTrue);
      expect(TxDestination.isValidReference(Uint8List(16)), isTrue);
      expect(() => TxDestination.encodeMemo('AB-CD-EF'), throwsArgumentError);
      expect(() => TxDestination.encodeMemo('ABC-'), throwsArgumentError);
      expect(() => TxDestination.encodeMemo('-123'), throwsArgumentError);
      expect(
          () => TxDestination.encodeMemo('123-456-789'), throwsArgumentError);
      expect(() => TxDestination.encodeMemo('ABCDEFGHIJKLMNOPQ'),
          throwsArgumentError);
      final trailingDash = Uint8List(16);
      trailingDash.setRange(0, 16, 'AAAAAAAAAAAAAAA-'.codeUnits);
      expect(TxDestination.isValidReference(trailingDash), isFalse);
    });
  });

  group('a signed spend', () {
    late WOTSWallet source;
    late WOTSWallet change;

    setUp(() {
      final sourceSecret = Uint8List(32)..fillRange(0, 32, 0x11);
      final changeSecret = Uint8List(32)..fillRange(0, 32, 0x22);
      source = WOTSWallet.create('source', sourceSecret);
      change = WOTSWallet.create('change', changeSecret, source.getAddrTag());
    });

    test('matches the node layout and recovers the public key', () {
      final low = Uint8List(20)..fillRange(0, 20, 0x02);
      final high = Uint8List(20)..fillRange(0, 20, 0x01);
      final spend = MochimoTransaction.sign(
        source: source,
        change: change,
        destinations: [
          TxDestination(tag: low, amount: BigInt.from(40), memo: 'B-1'),
          TxDestination(tag: high, amount: BigInt.from(60)),
        ],
        changeAmount: BigInt.from(80),
        fee: BigInt.from(20),
      );

      expect(spend.bytes.length, 116 + 44 * 2 + 2208);
      expect(spend.bytes.sublist(0, 4), [0, 0, 1, 0]);
      expect(spend.sourceAddress.sublist(0, 20), source.getAddrTag());
      expect(spend.changeAddressBytes.sublist(0, 20), source.getAddrTag());
      expect(spend.changeAddressBytes.sublist(20),
          isNot(equals(spend.sourceAddress.sublist(20))));
      expect(spend.bytes.sublist(84, 92),
          MochimoTransaction.uint64(BigInt.from(100)));
      expect(spend.bytes.sublist(116, 136), high);
      expect(spend.bytes.sublist(160, 180), low);
      expect(spend.bytes.sublist(spend.bytes.length - 12),
          [0x42, 0, 0, 0, 0x0e, 0, 0, 0, 0x01, 0, 0, 0]);

      final publicKey = source.getWots()!.sublist(0, WOTS.WOTSSIGBYTES);
      final publicSeed =
          source.getWots()!.sublist(WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32);
      final addressSeed = source.getWots()!.sublist(WOTS.WOTSSIGBYTES + 32);
      final recovered = WOTS.wotsPkFromSig(
          spend.signature, spend.messageHash(), publicSeed, addressSeed);
      expect(recovered, publicKey);

      final packet = Datagram()
        ..setOperation(Operation.transaction)
        ..setPayload(spend.bytes);
      final parsed = Datagram.of(packet.serialize());
      expect(parsed.getOperation(), Operation.transaction);
      expect(parsed.getPayload(), spend.bytes);
    });

    test('rejects a destination that spends back to the source tag', () {
      expect(
          () => MochimoTransaction.sign(
                source: source,
                change: change,
                destinations: [
                  TxDestination(tag: source.getAddrTag()!, amount: BigInt.one),
                ],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
    });

    test('rejects a change key that repeats the source hash', () {
      expect(
          () => MochimoTransaction.sign(
                source: source,
                change: source,
                destinations: [
                  TxDestination(
                      tag: Uint8List(20)..[0] = 9, amount: BigInt.one),
                ],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
    });

    test('rejects malformed fields before signing', () {
      expect(
          () => MochimoTransaction.sign(
                source: WOTSWallet(),
                change: WOTSWallet(),
                destinations: [
                  TxDestination(tag: Uint8List(20), amount: BigInt.one),
                ],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsStateError);
      expect(
          () => MochimoTransaction.changeAddress(Uint8List(4), Uint8List(32)),
          throwsArgumentError);

      final seed = Uint8List(32);
      final wots = Uint8List(2208);
      final tag = Uint8List(20)..[0] = 1;
      final change = MochimoTransaction.changeAddress(
          tag, Uint8List(2144)..[0] = 9);
      final good =
          TxDestination(tag: Uint8List(20)..[0] = 2, amount: BigInt.one);
      expect(
          () => MochimoTransaction.signWithKey(
                signingSeed: Uint8List(8),
                sourceWots: wots,
                accountTag: tag,
                changeAddress: change,
                destinations: [good],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
      expect(
          () => MochimoTransaction.signWithKey(
                signingSeed: seed,
                sourceWots: Uint8List(10),
                accountTag: tag,
                changeAddress: change,
                destinations: [good],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
      expect(
          () => MochimoTransaction.signWithKey(
                signingSeed: seed,
                sourceWots: wots,
                accountTag: Uint8List(4),
                changeAddress: change,
                destinations: [good],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
      expect(
          () => MochimoTransaction.signWithKey(
                signingSeed: seed,
                sourceWots: wots,
                accountTag: tag,
                changeAddress: Uint8List(8),
                destinations: [good],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
      expect(
          () => MochimoTransaction.signWithKey(
                signingSeed: seed,
                sourceWots: wots,
                accountTag: tag,
                changeAddress: change,
                destinations: List.filled(
                    257,
                    TxDestination(
                        tag: Uint8List(20)..[0] = 3, amount: BigInt.one)),
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
      final wrongTag = Uint8List.fromList(change);
      wrongTag[0] ^= 0xff;
      expect(
          () => MochimoTransaction.signWithKey(
                signingSeed: seed,
                sourceWots: wots,
                accountTag: tag,
                changeAddress: wrongTag,
                destinations: [good],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
      expect(
          () => MochimoTransaction.signWithKey(
                signingSeed: seed,
                sourceWots: wots,
                accountTag: tag,
                changeAddress: change,
                destinations: [
                  TxDestination(tag: Uint8List(4), amount: BigInt.one),
                ],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
      expect(
          () => MochimoTransaction.signWithKey(
                signingSeed: seed,
                sourceWots: wots,
                accountTag: tag,
                changeAddress: change,
                destinations: [
                  TxDestination(
                      tag: Uint8List(20)..[0] = 2, amount: BigInt.zero),
                ],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
      final badReference = Uint8List(16)..[0] = 0x2d;
      expect(
          () => MochimoTransaction.signWithKey(
                signingSeed: seed,
                sourceWots: wots,
                accountTag: tag,
                changeAddress: change,
                destinations: [
                  TxDestination(
                      tag: Uint8List(20)..[0] = 2,
                      amount: BigInt.one,
                      reference: badReference),
                ],
                changeAmount: BigInt.one,
                fee: BigInt.one,
              ),
          throwsArgumentError);
      expect(() => MochimoTransaction.uint64(BigInt.from(-1)),
          throwsArgumentError);
      expect(() => MochimoTransaction.uint64(BigInt.one << 64),
          throwsArgumentError);
      expect(
          MochimoTransaction.readUint64(
              MochimoTransaction.uint64(BigInt.from(1000)), 0),
          BigInt.from(1000));
    });

    test('keeps two identical destinations in order', () {
      final tag = Uint8List(20)..[0] = 4;
      final spend = MochimoTransaction.sign(
        source: source,
        change: change,
        destinations: [
          TxDestination(tag: tag, amount: BigInt.from(5)),
          TxDestination(tag: tag, amount: BigInt.from(5)),
        ],
        changeAmount: BigInt.one,
        fee: BigInt.one,
      );
      expect(spend.destinationCount, 2);
      expect(spend.bytes.sublist(116, 160), spend.bytes.sublist(160, 204));
    });
  });
}
