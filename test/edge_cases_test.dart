import 'dart:typed_data';

import 'package:mochimo_wots/core/hasher/mochimo_hasher.dart';
import 'package:mochimo_wots/core/model/byte_buffer.dart';
import 'package:mochimo_wots/core/protocol/datagram.dart';
import 'package:mochimo_wots/core/protocol/tags.dart';
import 'package:mochimo_wots/core/protocol/wots.dart';
import 'package:mochimo_wots/core/protocol/wots_address.dart';
import 'package:mochimo_wots/core/protocol/wots_hash.dart';
import 'package:mochimo_wots/core/protocol/wots_wallet.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';
import 'package:mochimo_wots/core/utils/crc16.dart';
import 'package:test/test.dart';

void main() {
  final secret = Uint8List(32)..fillRange(0, 32, 0x07);

  group('rejected inputs', () {
    test('byte buffer rejects overflow, a bad slice, and a wrong type', () {
      final full = ByteBuffer.allocate(1)..put(0x11);
      expect(() => full.put(0x22), throwsRangeError);

      final dest = ByteBuffer.allocate(8);
      final src = Uint8List.fromList([1, 2, 3]);
      expect(() => dest.put(src, -1), throwsRangeError);
      expect(() => dest.put(src, 1, 3), throwsRangeError);
      expect(() => dest.put('no'), throwsArgumentError);
    });

    test('byte helpers reject bad arguments and convert both ways', () {
      expect(ByteUtils.bytesToLittleEndian(Uint8List.fromList([1, 2, 3])),
          Uint8List.fromList([3, 2, 1]));
      expect(ByteUtils.toBytes(0x1234, 2), Uint8List.fromList([0x12, 0x34]));
      expect(ByteUtils.toBytes(BigInt.from(0x1234), 2),
          Uint8List.fromList([0x12, 0x34]));
      expect(ByteUtils.toHexString(255), '0xff');
      expect(() => ByteUtils.fit(1, 4), throwsArgumentError);
      expect(() => ByteUtils.bytesToHex(Uint8List(2), -1), throwsArgumentError);
      expect(
          () => ByteUtils.bytesToHex(Uint8List(2), 0, 3), throwsArgumentError);
      expect(() => ByteUtils.toBytes('no', 1), throwsArgumentError);
      expect(() => ByteUtils.toLittleEndian(Uint8List(2), -1),
          throwsArgumentError);
      expect(() => ByteUtils.toLittleEndian(Uint8List(2), 0, 3),
          throwsArgumentError);
    });

    test(
        'crc16 rejects a negative offset, a negative length, and a short buffer',
        () {
      final data = Uint8List(4);
      expect(() => CRC16.crc(data, -1, 1), throwsArgumentError);
      expect(() => CRC16.crc(data, 0, -1), throwsArgumentError);
      expect(() => CRC16.crc(data, 0, 5), throwsArgumentError);
    });

    test('hasher rejects an unknown algorithm and a bad window', () {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      expect(() => MochimoHasher.hashWith('md5', data), throwsArgumentError);
      final hasher = MochimoHasher();
      expect(() => hasher.update(data, -1), throwsArgumentError);
      expect(() => hasher.update(data, 0, 5), throwsArgumentError);
      expect(MochimoHasher.hash(data, 1, 2),
          MochimoHasher.hash(Uint8List.fromList([2, 3])));
    });

    test('a wots suffix tag must be 12 bytes and the address 2208', () {
      expect(() => Tag.tag(Uint8List(2208), Uint8List(4)), throwsArgumentError);
      expect(() => Tag.tag(Uint8List(10), Uint8List(Tag.TAG_LENGTH)),
          throwsArgumentError);
    });

    test('prf, address words, and the published suffix reject the wrong size',
        () {
      expect(() => WOTSHash.prf(Uint8List(32), 0, Uint8List(16), Uint8List(32)),
          throwsArgumentError);
      expect(() => WOTS.addressBuffer(Uint8List(16)), throwsArgumentError);
      expect(() => WOTS.stampAddressSuffix(Uint8List(16)), throwsArgumentError);
    });

    test('signing and splitting reject short or mismatched components', () {
      expect(
          () => WOTS.wotsSign(Uint8List(WOTS.WOTSSIGBYTES), Uint8List(16),
              secret, secret, 0, secret),
          throwsArgumentError);
      expect(
          () => WOTS.wotsPkFromSig(
              Uint8List(WOTS.WOTSSIGBYTES), Uint8List(16), secret, secret),
          throwsArgumentError);
      expect(() => WOTS.generateAddress(null, Uint8List(16), (_) => {}),
          throwsArgumentError);
      expect(
          () => WOTS.generateAddress(
              Uint8List(4), secret, WOTSWallet.componentsGenerator),
          throwsArgumentError);
      expect(() => WOTS.generateRandomAddress(Uint8List(4), secret),
          throwsArgumentError);

      expect(
          () => WOTS.isValidWithComponents(Uint8List(16),
              Uint8List(WOTS.WOTSSIGBYTES), secret, secret, (_) {}),
          throwsArgumentError);
      expect(
          () => WOTS.isValidWithComponents(
              secret, Uint8List(8), secret, secret, (_) {}),
          throwsArgumentError);
      expect(
          () => WOTS.isValidWithComponents(secret, Uint8List(WOTS.WOTSSIGBYTES),
              Uint8List(8), secret, (_) {}),
          throwsArgumentError);
      expect(
          () => WOTS.isValidWithComponents(secret, Uint8List(WOTS.WOTSSIGBYTES),
              secret, Uint8List(8), (_) {}),
          throwsArgumentError);

      final pk = Uint8List(WOTS.WOTSSIGBYTES);
      final pub = Uint8List(WOTS.PARAMSN);
      final addr = Uint8List(WOTS.PARAMSN);
      expect(() => WOTS.splitAddress(Uint8List(10), pk, pub, addr, null),
          throwsArgumentError);
      expect(
          () =>
              WOTS.splitAddress(Uint8List(2208), pk, Uint8List(8), addr, null),
          throwsArgumentError);
      expect(
          () => WOTS.splitAddress(Uint8List(2208), pk, pub, Uint8List(8), null),
          throwsArgumentError);
      expect(
          () => WOTS.splitAddress(Uint8List(2208), pk, pub, addr, Uint8List(4)),
          throwsArgumentError);
    });

    test('account amounts and implicit tags reject a short buffer', () {
      expect(() => WotsAddress().setAmountBytes(Uint8List(4)),
          throwsArgumentError);
      expect(() => WotsAddress.addrFromImplicit(Uint8List(12)),
          throwsArgumentError);
    });

    test('a datagram rejects a weight of the wrong size and a short frame', () {
      expect(
          () => Datagram().setWeightBytes(Uint8List(16)), throwsArgumentError);

      final short = Uint8List(DatagramConstants.headerLength + 4);
      short[DatagramConstants.TRANSACTION_BUFFER_LENGTH_OFFSET] = 10;
      expect(() => Datagram.of(short), throwsArgumentError);
    });

    test(
        'a wallet rejects a bad secret, a bad account tag, and a short wots blob',
        () {
      expect(() => WOTSWallet(secret: Uint8List(16)), throwsArgumentError);
      expect(() => WOTSWallet(addrTag: Uint8List(12)), throwsArgumentError);
      expect(() => WOTSWallet.create('bad', secret, Uint8List(19)),
          throwsArgumentError);

      expect(() => WOTSWallet(wots: Uint8List(10), secret: secret),
          throwsArgumentError);

      final secretOnly = WOTSWallet(secret: secret);
      expect(secretOnly.hasSecret(), isTrue);
      expect(() => secretOnly.sign(Uint8List(1)), throwsStateError);

      final empty = WOTSWallet();
      expect(empty.hasSecret(), isFalse);
      expect(empty.getAddrTagBase58(), isNull);
    });
  });

  group('expected protocol paths', () {
    test('base w reads the same digits as the offset form', () {
      final msg = Uint8List.fromList([0xab]);
      final direct = List<int>.filled(2, 0);
      final offset = List<int>.filled(2, 0);
      WOTS.baseW(msg, direct);
      WOTS.baseW_(msg, offset, 0, direct.length);
      expect(direct, offset);
      expect(direct, isNot(equals([0, 0])));
    });

    test('weight is a 32-byte little-endian integer and the version is 4', () {
      final datagram = Datagram()
        ..setWeight(BigInt.from(0x010203))
        ..setTransactionBufferLength(0);
      expect(datagram.getTransactionBufferLength(), 0);
      expect(datagram.getVersion(), DatagramConstants.version);
      expect(datagram.getWeight().sublist(0, 3), [0x03, 0x02, 0x01]);

      final roundTrip = Datagram.of(datagram.serialize());
      expect(roundTrip.getWeight(), datagram.getWeight());
      expect(roundTrip.getVersion(), DatagramConstants.version);
    });

    test('a non-transaction payload is kept as an opaque body', () {
      final raw = Uint8List(DatagramConstants.headerLength + 4 + 4);
      raw[0] = DatagramConstants.version;
      raw[2] = 0x39;
      raw[3] = 0x05;
      raw[8] = Operation.hello.value;
      raw[DatagramConstants.TRANSACTION_BUFFER_LENGTH_OFFSET] = 4;
      raw[DatagramConstants.TRANSACTION_BUFFER_OFFSET] = 0xff;
      raw[raw.length - 2] = 0xcd;
      raw[raw.length - 1] = 0xab;

      final datagram = Datagram.of(raw);
      expect(datagram.getOperation(), Operation.hello);
      expect(datagram.getTransactionBufferLength(), 4);
      expect(datagram.getPayload(), Uint8List.fromList([0xff, 0, 0, 0]));
    });

    test('an omitted account tag is the implicit address', () {
      final wallet = WOTSWallet.create('implicit', secret);
      final tag = wallet.getAddrTag()!;
      final hash = wallet.getAddrHash()!;
      expect(tag, hash);
      expect(wallet.getAddress(), Uint8List.fromList([...tag, ...hash]));
      expect(wallet.hasSecret(), isTrue);
      expect(wallet.getAddrTagBase58(), isNotNull);
    });

    test('a 32-byte input is the digest, and a changed byte fails', () {
      final wallet = WOTSWallet.create('implicit', secret);
      final message = Uint8List.fromList('Hello, Mochimo!'.codeUnits);
      final digest = MochimoHasher.hash(message);
      expect(WOTSWallet.messageDigest(digest), digest);
      expect(wallet.sign(digest), wallet.sign(message));

      final signature = wallet.sign(Uint8List(0));
      expect(wallet.verify(Uint8List(0), signature), isTrue);
      signature[0] ^= 0xff;
      expect(wallet.verify(Uint8List(0), signature), isFalse);
      expect(wallet.verify(Uint8List.fromList([1]), wallet.sign(Uint8List(0))),
          isFalse);
    });

    test('a 12-byte wots suffix is stored and a mismatched key is rejected',
        () {
      final suffix = Uint8List(12)..fillRange(0, 12, 0x5a);
      final address =
          WOTS.generateAddress(suffix, secret, WOTSWallet.componentsGenerator);
      expect(address.sublist(address.length - 12), suffix);

      final pk = Uint8List(WOTS.WOTSSIGBYTES);
      final pubSeed = Uint8List(WOTS.PARAMSN);
      final addrSeed = Uint8List(WOTS.PARAMSN);
      final copied = Uint8List(12);
      WOTS.splitAddress(address, pk, pubSeed, addrSeed, copied);
      expect(copied, suffix);
      expect(
          pubSeed, address.sublist(WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32));

      final components = WOTSWallet.componentsGenerator(secret);
      pk[0] ^= 0xff;
      expect(
          WOTS.isValidWithComponents(components['private_seed']!, pk, pubSeed,
              addrSeed, (bytes) => bytes.fillRange(0, bytes.length, 1)),
          isFalse);
    });
  });
}
