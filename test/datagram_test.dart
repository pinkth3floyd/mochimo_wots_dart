import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mochimo_wots/core/protocol/datagram.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';

void main() {
  group('Datagram', () {
    group('serialization', () {
      test('should serialize and deserialize datagram', () {
        final datagram = Datagram();

        // Set test values
        datagram.setId1(1234);
        datagram.setId2(5678);
        datagram.setOperation(Operation.transaction);
        datagram.setCurrentBlockHeight(BigInt.from(1000));
        datagram.setBlocknum(BigInt.from(2000));

        datagram.setPayload(Uint8List.fromList([1, 2, 3, 4]));

        // Serialize and deserialize
        final serialized = datagram.serialize();
        final deserialized = Datagram.of(serialized);

        // Verify all fields match
        expect(deserialized.getId1(), equals(1234));
        expect(deserialized.getId2(), equals(5678));
        expect(deserialized.getOperation(), equals(Operation.transaction));
        expect(deserialized.getCurrentBlockHeight(), equals(BigInt.from(1000)));
        expect(deserialized.getBlocknum(), equals(BigInt.from(2000)));
        expect(deserialized.getPayload(), Uint8List.fromList([1, 2, 3, 4]));
      });

      test('should handle invalid operation code', () {
        final buffer = Uint8List(DatagramConstants.headerLength + 4);
        buffer[8] = 0xff;
        expect(() => Datagram.of(buffer), throwsA(isA<StateError>()));
      });

      test('should handle invalid data length', () {
        final buffer = Uint8List(10);
        expect(() => Datagram.of(buffer), throwsA(isA<ArgumentError>()));
      });

      test('should use the node network id and trailer', () {
        final datagram = Datagram();
        final serialized = datagram.serialize();
        expect(serialized[0], equals(DatagramConstants.version));
        expect(serialized[2], equals(0x39));
        expect(serialized[3], equals(0x05));
        expect(serialized[serialized.length - 2], equals(0xcd));
        expect(serialized[serialized.length - 1], equals(0xab));
        expect(datagram.getNetwork(), equals(DatagramConstants.networkId));
        expect(datagram.getTrailer(), equals(DatagramConstants.trailer));
      });
    });

    group('route handling', () {
      test('should convert route to weight', () {
        final route = ['192.168.1.1', '10.0.0.1'];
        final weight = Datagram.getRouteAsWeight(route);

        // First IP
        expect(weight[0], equals(192));
        expect(weight[1], equals(168));
        expect(weight[2], equals(1));
        expect(weight[3], equals(1));

        // Second IP
        expect(weight[4], equals(10));
        expect(weight[5], equals(0));
        expect(weight[6], equals(0));
        expect(weight[7], equals(1));

        // Rest should be zeros
        expect(weight.sublist(8).every((b) => b == 0), isTrue);
      });

      test('should handle multiple IPs', () {
        final route = ['192.168.1.1', '10.0.0.1', '172.16.0.1', '127.0.0.1'];
        final weight = Datagram.getRouteAsWeight(route);

        // Should only use last 8 IPs (32 bytes)
        expect(weight[0], equals(192));
        expect(weight[1], equals(168));
        expect(weight[2], equals(1));
        expect(weight[3], equals(1));

        expect(weight[4], equals(10));
        expect(weight[5], equals(0));
        expect(weight[6], equals(0));
        expect(weight[7], equals(1));

        expect(weight[8], equals(172));
        expect(weight[9], equals(16));
        expect(weight[10], equals(0));
        expect(weight[11], equals(1));

        expect(weight[12], equals(127));
        expect(weight[13], equals(0));
        expect(weight[14], equals(0));
        expect(weight[15], equals(1));
      });

      test('should handle invalid IPs', () {
        expect(() => Datagram.getRouteAsWeight(['invalid.ip']),
            throwsA(isA<ArgumentError>()));
        expect(() => Datagram.getRouteAsWeight(['256.1.2.3']),
            throwsA(isA<ArgumentError>()));
        expect(() => Datagram.getRouteAsWeight(['1.2.3']),
            throwsA(isA<ArgumentError>()));
      });

      test('should parse transaction IPs', () {
        final datagram = Datagram();

        // Set weight with IP addresses
        final weight = Uint8List(32);
        weight.setRange(0, 8, [192, 168, 1, 1, 10, 0, 0, 1]);
        datagram.setWeightBytes(weight);

        final ips = Datagram.parseTxIps(datagram);

        expect(ips.contains('192.168.1.1'), isTrue);
        expect(ips.contains('10.0.0.1'), isTrue);
      });
    });

    group('payload length', () {
      test('should report the bytes that follow the header', () {
        final datagram = Datagram();
        datagram.serialize();
        expect(datagram.getTransactionBufferLength(), equals(0));
      });
    });

    group('CRC handling', () {
      test('should handle undefined CRC', () {
        final datagram = Datagram();
        expect(datagram.getCRC(), equals(0));
      });

      test('should calculate and store CRC during serialization', () {
        final datagram = Datagram();
        datagram.setId1(1234);
        datagram.setId2(5678);

        final serialized = datagram.serialize();
        expect(datagram.getCRC(), isNot(0));

        // Deserialize and verify CRC matches
        final deserialized = Datagram.of(serialized);
        expect(deserialized.getCRC(), equals(datagram.getCRC()));
      });
    });

    group('payload', () {
      test('should round-trip the bytes after the header', () {
        final datagram = Datagram();
        final payload = Uint8List.fromList([9, 8, 7]);
        datagram.setPayload(payload);
        expect(datagram.getPayload(), payload);
        expect(datagram.getTransactionBufferLength(), 3);

        final parsed = Datagram.of(datagram.serialize());
        expect(parsed.getPayload(), payload);
      });

      test('should reject a payload longer than 65535 bytes', () {
        expect(
            () => Datagram().setPayload(Uint8List(65536)), throwsArgumentError);
      });

      test('should build a balance query and read a ledger entry', () {
        final address = Uint8List(40)..fillRange(0, 40, 0xab);
        final query = Datagram.balanceQuery(address);
        expect(query.getOperation(), Operation.balance);
        expect(query.getPayload(), address);

        final entry = Uint8List(48);
        entry.setRange(0, 40, address);
        entry[40] = 10;
        final ledger = Datagram.readLedgerEntry(entry);
        expect(ledger.address, address);
        expect(ledger.balance, BigInt.from(10));
        expect(() => Datagram.balanceQuery(Uint8List(20)), throwsArgumentError);
        expect(
            () => Datagram.readLedgerEntry(Uint8List(40)), throwsArgumentError);
      });
    });

    group('block handling', () {
      test('should handle block hashes', () {
        final datagram = Datagram();
        final hash = Uint8List(32)..fillRange(0, 32, 0x77);

        datagram.setCurrentBlockHash(hash);
        expect(ByteUtils.areEqual(datagram.getCblockhash(), hash), isTrue);

        datagram.setPreviousBlockHash(hash);
        expect(ByteUtils.areEqual(datagram.getPblockhash(), hash), isTrue);

        expect(() => datagram.setCurrentBlockHash(Uint8List(10)),
            throwsA(isA<ArgumentError>()));
        expect(() => datagram.setPreviousBlockHash(Uint8List(10)),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle block numbers', () {
        final datagram = Datagram();

        datagram.setCurrentBlockHeight(BigInt.from(1000));
        expect(datagram.getCurrentBlockHeight(), equals(BigInt.from(1000)));

        datagram.setBlocknum(BigInt.from(2000));
        expect(datagram.getBlocknum(), equals(BigInt.from(2000)));
      });
    });

    group('cloning', () {
      test('should create exact copy', () {
        final original = Datagram();
        original.setId1(1234);
        original.setId2(5678);
        original.setOperation(Operation.transaction);
        original.setCurrentBlockHeight(BigInt.from(1000));

        final clone = original.clone();

        expect(clone.getId1(), equals(original.getId1()));
        expect(clone.getId2(), equals(original.getId2()));
        expect(clone.getOperation(), equals(original.getOperation()));
        expect(clone.getCurrentBlockHeight(),
            equals(original.getCurrentBlockHeight()));
        expect(clone.getCRC(), equals(original.getCRC()));
      });
    });
  });
}
