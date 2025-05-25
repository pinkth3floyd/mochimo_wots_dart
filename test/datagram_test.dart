import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mochimo_wots/core/model/byte_buffer.dart';
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

        final sourceAddr = Uint8List(2208)..fillRange(0, 2208, 0x11);
        final destAddr = Uint8List(2208)..fillRange(0, 2208, 0x22);
        final changeAddr = Uint8List(2208)..fillRange(0, 2208, 0x33);

        datagram.setSourceAddress(sourceAddr);
        datagram.setDestinationAddress(destAddr);
        datagram.setChangeAddress(changeAddr);

        datagram.setTotalSendBigInt(BigInt.from(1000000));
        datagram.setTotalChangeBigInt(BigInt.from(500000));
        datagram.setFeeBigInt(BigInt.from(10000));

        final signature = Uint8List(2144)..fillRange(0, 2144, 0x44);
        datagram.setSignature(signature);

        // Serialize and deserialize
        final serialized = datagram.serialize();
        final deserialized = Datagram.of(serialized);

        // Verify all fields match
        expect(deserialized.getId1(), equals(1234));
        expect(deserialized.getId2(), equals(5678));
        expect(deserialized.getOperation(), equals(Operation.transaction));
        expect(deserialized.getCurrentBlockHeight(), equals(BigInt.from(1000)));
        expect(deserialized.getBlocknum(), equals(BigInt.from(2000)));

        expect(ByteUtils.areEqual(deserialized.getSourceAddress(), sourceAddr),
            isTrue);
        expect(
            ByteUtils.areEqual(deserialized.getDestinationAddress(), destAddr),
            isTrue);
        expect(ByteUtils.areEqual(deserialized.getChangeAddress(), changeAddr),
            isTrue);

        expect(
            ByteUtils.areEqual(deserialized.getSignature(), signature), isTrue);
      });

      test('should handle invalid operation code', () {
        final buffer = Uint8List(8920);
        expect(() => Datagram.of(buffer), throwsA(isA<StateError>()));
      });

      test('should handle invalid data length', () {
        final buffer = Uint8List(8919); // Too short
        expect(() => Datagram.of(buffer), throwsA(isA<ArgumentError>()));
      });
    });

    group('capabilities', () {
      test('should parse capabilities', () {
        final datagram = Datagram();

        // Set some capabilities using the public method
        datagram.setCapability(Capability.push, true);
        datagram.setCapability(Capability.wallet, true);

        final capabilities = Datagram.parseCapabilities(datagram);

        expect(capabilities.contains(Capability.push), isTrue);
        expect(capabilities.contains(Capability.wallet), isTrue);
        expect(capabilities.contains(Capability.sanctuary), isFalse);
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

    group('peer list handling', () {
      test('should handle add to peer list flag', () {
        final datagram = Datagram();

        datagram.setAddToPeerList(true);
        expect(datagram.isAddToPeerList(), isTrue);
        expect(datagram.getTransactionBufferLength(), equals(0));

        datagram.setAddToPeerList(false);
        expect(datagram.isAddToPeerList(), isFalse);
        expect(datagram.getTransactionBufferLength(), equals(1));
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

    group('address handling', () {
      test('should handle source address', () {
        final datagram = Datagram();
        final addr = Uint8List(2208)..fillRange(0, 2208, 0x11);

        datagram.setSourceAddress(addr);
        expect(ByteUtils.areEqual(datagram.getSourceAddress(), addr), isTrue);

        // Should throw on invalid length
        expect(() => datagram.setSourceAddress(Uint8List(10)),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle destination address', () {
        final datagram = Datagram();
        final addr = Uint8List(2208)..fillRange(0, 2208, 0x22);

        datagram.setDestinationAddress(addr);
        expect(
            ByteUtils.areEqual(datagram.getDestinationAddress(), addr), isTrue);

        expect(() => datagram.setDestinationAddress(Uint8List(10)),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle change address', () {
        final datagram = Datagram();
        final addr = Uint8List(2208)..fillRange(0, 2208, 0x33);

        datagram.setChangeAddress(addr);
        expect(ByteUtils.areEqual(datagram.getChangeAddress(), addr), isTrue);

        expect(() => datagram.setChangeAddress(Uint8List(10)),
            throwsA(isA<ArgumentError>()));
      });
    });

    group('amount handling', () {
      test('should handle total send amount', () {
        final datagram = Datagram();
        final amount = Uint8List(8)..fillRange(0, 8, 0x44);

        datagram.setTotalSend(amount);
        expect(ByteUtils.areEqual(datagram.getTotalSend(), amount), isTrue);

        // Test bigint version
        datagram.setTotalSendBigInt(BigInt.from(1000000));
        final buffer = ByteBuffer.wrap(datagram.getTotalSend());
        expect(ByteUtils.readLittleEndianUnsigned(buffer).toInt(),
            equals(1000000));

        expect(() => datagram.setTotalSend(Uint8List(10)),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle total change amount', () {
        final datagram = Datagram();
        final amount = Uint8List(8)..fillRange(0, 8, 0x55);

        datagram.setTotalChange(amount);
        expect(ByteUtils.areEqual(datagram.getTotalChange(), amount), isTrue);

        datagram.setTotalChangeBigInt(BigInt.from(500000));
        final buffer = ByteBuffer.wrap(datagram.getTotalChange());
        expect(
            ByteUtils.readLittleEndianUnsigned(buffer).toInt(), equals(500000));

        expect(() => datagram.setTotalChange(Uint8List(10)),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle fee amount', () {
        final datagram = Datagram();
        final amount = Uint8List(8)..fillRange(0, 8, 0x66);

        datagram.setFee(amount);
        expect(ByteUtils.areEqual(datagram.getFee(), amount), isTrue);

        datagram.setFeeBigInt(BigInt.from(10000));
        final buffer = ByteBuffer.wrap(datagram.getFee());
        expect(
            ByteUtils.readLittleEndianUnsigned(buffer).toInt(), equals(10000));

        expect(() => datagram.setFee(Uint8List(10)),
            throwsA(isA<ArgumentError>()));
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

    group('signature handling', () {
      test('should handle signature', () {
        final datagram = Datagram();
        final sig = Uint8List(2144)..fillRange(0, 2144, 0x88);

        datagram.setSignature(sig);
        expect(ByteUtils.areEqual(datagram.getSignature(), sig), isTrue);

        expect(() => datagram.setSignature(Uint8List(10)),
            throwsA(isA<ArgumentError>()));
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
