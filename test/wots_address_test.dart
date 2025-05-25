import 'package:test/test.dart';
import 'dart:typed_data';
import 'package:mochimo_wots/core/protocol/wots_address.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';
import 'package:mochimo_wots/core/hasher/mochimo_hasher.dart';

void main() {
  group('WotsAddress', () {
    group('basic operations', () {
      late WotsAddress wotsAddr;

      setUp(() {
        wotsAddr = WotsAddress();
      });

      test('should initialize with zero amount', () {
        expect(wotsAddr.getAmount(), equals(BigInt.zero));
        expect(wotsAddr.bytes().length, equals(48)); // TXADDRLEN + TXAMOUNT
      });

      test('should handle tag operations correctly', () {
        final tag = Uint8List(WotsAddress.ADDR_TAG_LEN)
          ..fillRange(0, WotsAddress.ADDR_TAG_LEN, 0x12);
        wotsAddr.setTag(tag);

        final retrievedTag = wotsAddr.getTag();
        expect(retrievedTag.length, equals(WotsAddress.ADDR_TAG_LEN));
        expect(ByteUtils.areEqual(retrievedTag, tag), isTrue);
      });

      test('should handle address operations correctly', () {
        final addrHash =
            Uint8List(WotsAddress.TXADDRLEN - WotsAddress.ADDR_TAG_LEN)
              ..fillRange(
                  0, WotsAddress.TXADDRLEN - WotsAddress.ADDR_TAG_LEN, 0x34);
        wotsAddr.setAddrHash(addrHash);

        final retrievedAddrHash = wotsAddr.getAddrHash();
        // Should only get the non-tag portion
        expect(
            retrievedAddrHash.length,
            equals(WotsAddress.TXADDRLEN -
                WotsAddress.ADDR_TAG_LEN)); // TXADDRLEN - ADDR_TAG_LEN
        // Verify the content as well
        expect(ByteUtils.areEqual(retrievedAddrHash, addrHash), isTrue);
      });

      test('should handle amount operations correctly', () {
        final testAmount = BigInt.parse("123456789");
        final amountBytes = Uint8List(8);
        final dataView = ByteData.view(amountBytes.buffer);
        dataView.setUint64(0, testAmount.toInt(), Endian.little);

        wotsAddr.setAmountBytes(amountBytes);
        expect(wotsAddr.getAmount(), equals(testAmount));

        final retrievedAmountBytes = wotsAddr.getAmountBytes();
        expect(ByteUtils.areEqual(retrievedAmountBytes, amountBytes), isTrue);
      });

      test('should serialize to bytes correctly', () {
        final tag = Uint8List(WotsAddress.ADDR_TAG_LEN)
          ..fillRange(0, WotsAddress.ADDR_TAG_LEN, 0x12);

        final addrHashPart =
            Uint8List(WotsAddress.TXADDRLEN - WotsAddress.ADDR_TAG_LEN)
              ..fillRange(
                  0, WotsAddress.TXADDRLEN - WotsAddress.ADDR_TAG_LEN, 0x34);

        final testAmount = BigInt.parse("123456789");
        final amountBytes = Uint8List(8);
        final dataView = ByteData.view(amountBytes.buffer);
        dataView.setUint64(0, testAmount.toInt(), Endian.little);

        wotsAddr.setTag(tag);
        wotsAddr.setAddrHash(addrHashPart); // Set the hash part
        wotsAddr.setAmountBytes(amountBytes);

        final bytes = wotsAddr.bytes();
        expect(bytes.length, equals(48)); // TXADDRLEN (40) + TXAMOUNT (8)
        expect(
            ByteUtils.areEqual(bytes.sublist(0, WotsAddress.ADDR_TAG_LEN), tag),
            isTrue); // Check tag part
        expect(
            ByteUtils.areEqual(
                bytes.sublist(WotsAddress.ADDR_TAG_LEN, WotsAddress.TXADDRLEN),
                addrHashPart),
            isTrue); // Check addrHash part
        expect(
            ByteUtils.areEqual(
                bytes.sublist(WotsAddress.TXADDRLEN, 48), amountBytes),
            isTrue); // Check amount part
      });
    });

    group('wotsAddressFromBytes', () {
      test('should create from WOTS public key', () {
        final wotsPK = Uint8List(2144)..fillRange(0, 2144, 0x56);
        final result = WotsAddress.wotsAddressFromBytes(wotsPK);
        expect(result, isA<WotsAddress>());
        expect(result.bytes().length, equals(48));
        // Additional check: the address and amount should be derived/defaulted
        expect(result.getAmount(), equals(BigInt.zero));
        expect(result.getAddress().any((b) => b != 0),
            isTrue); // Should not be all zeros if hash generates non-zero
      });

      test('should create from address bytes (TXADDRLEN)', () {
        final addrBytes = Uint8List(WotsAddress.TXADDRLEN)
          ..fillRange(0, WotsAddress.TXADDRLEN, 0x78);
        final result = WotsAddress.wotsAddressFromBytes(addrBytes);
        expect(result, isA<WotsAddress>());
        expect(result.bytes().length,
            equals(48)); // Still 48 because it includes default amount
        expect(result.getAmount(),
            equals(BigInt.zero)); // Should have default zero amount
        expect(ByteUtils.areEqual(result.getAddress(), addrBytes),
            isTrue); // Should match input address
      });

      test('should create from address with amount', () {
        final addr = Uint8List(WotsAddress.TXADDRLEN)
          ..fillRange(0, WotsAddress.TXADDRLEN, 0x78);
        final testAmount = BigInt.parse("123456789");
        final amountBytes = Uint8List(8);
        final dataView = ByteData.view(amountBytes.buffer);
        dataView.setUint64(0, testAmount.toInt(), Endian.little);

        final fullBytes =
            Uint8List(WotsAddress.TXADDRLEN + WotsAddress.TXAMOUNT);
        fullBytes.setAll(0, addr);
        fullBytes.setAll(WotsAddress.TXADDRLEN, amountBytes);

        final result = WotsAddress.wotsAddressFromBytes(fullBytes);

        // Add detailed checks
        expect(result, isA<WotsAddress>());
        expect(result.getAmount(), equals(testAmount));

        final resultBytes = result.bytes();

        // Check address part
        expect(
            ByteUtils.areEqual(resultBytes.sublist(0, WotsAddress.TXADDRLEN),
                fullBytes.sublist(0, WotsAddress.TXADDRLEN)),
            isTrue);

        // Check amount part
        expect(
            ByteUtils.areEqual(
                resultBytes
                    .sublist(WotsAddress.TXADDRLEN), // From TXADDRLEN to end
                fullBytes.sublist(WotsAddress.TXADDRLEN)),
            isTrue);

        // Finally check full bytes
        expect(ByteUtils.areEqual(resultBytes, fullBytes), isTrue);
      });
    });

    group('address generation', () {
      test('should generate implicit address correctly', () {
        final tag = Uint8List(WotsAddress.ADDR_TAG_LEN)
          ..fillRange(0, WotsAddress.ADDR_TAG_LEN, 0x12);
        final addr = WotsAddress.addrFromImplicit(tag);

        expect(addr.length, equals(WotsAddress.TXADDRLEN));
        expect(
            ByteUtils.areEqual(addr.sublist(0, WotsAddress.ADDR_TAG_LEN), tag),
            isTrue);
        // The second part of the address should be the tag bytes repeated to fill the remaining length
        final expectedSecondPart =
            Uint8List(WotsAddress.TXADDRLEN - WotsAddress.ADDR_TAG_LEN);
        for (int i = 0; i < expectedSecondPart.length; i++) {
          expectedSecondPart[i] = tag[i % tag.length];
        }
        expect(
            ByteUtils.areEqual(
                addr.sublist(WotsAddress.ADDR_TAG_LEN, WotsAddress.TXADDRLEN),
                expectedSecondPart),
            isTrue);
      });

      test('should generate hash correctly', () {
        final input = Uint8List(32)..fillRange(0, 32, 0x34);
        final hash = WotsAddress.addrHashGenerate(input);

        expect(hash.length, equals(20)); // RIPEMD160 output length

        // Test deterministic output
        final hash2 = WotsAddress.addrHashGenerate(input);
        expect(ByteUtils.areEqual(hash, hash2), isTrue);
      });

      test('should handle WOTS address conversion', () {
        final wotsPK = Uint8List(2144)..fillRange(0, 2144, 0x56);
        final addr = WotsAddress.addrFromWots(wotsPK);

        expect(addr, isNotNull);
        expect(addr!.length, equals(40));

        // Test invalid input
        final invalidWots = Uint8List(100);
        expect(WotsAddress.addrFromWots(invalidWots), isNull);
      });
    });

    group('hex conversion', () {
      test('should create from valid hex string', () {
        // Create a 40-byte hex string (TXADDRLEN * 2 hex chars)
        final baseHex =
            '1234567890abcdef'.repeat(3) + 'fedcba9876543210'.repeat(3);
        final validHex =
            baseHex.substring(0, WotsAddress.TXADDRLEN * 2); // 80 chars
        expect(validHex.length, equals(WotsAddress.TXADDRLEN * 2));

        final result = WotsAddress.wotsAddressFromHex(validHex);
        expect(result, isA<WotsAddress>());
        expect(result.bytes().length,
            equals(48)); // Total length including default amount
        expect(ByteUtils.bytesToHex(result.getAddress()), equals(validHex));
      });

      test('should handle invalid hex string (too short)', () {
        final invalidHex = '1234'; // Too short
        final result = WotsAddress.wotsAddressFromHex(invalidHex);
        expect(result, isA<WotsAddress>());
        expect(result.getAmount(), equals(BigInt.zero));
        // The address part should be all zeros for a default WotsAddress
        expect(result.getAddress().every((b) => b == 0), isTrue);
      });
    });

    group('addrFromWots', () {
      test('should generate address correctly with specific hash output', () {
        final wotsPK = Uint8List(2144)..fillRange(0, 2144, 0x42);
        final addr1 = WotsAddress.addrFromWots(wotsPK);

        expect(addr1, isNotNull);
        final finalAddrHex = ByteUtils.bytesToHex(addr1!);

        final sha3Hasher = MochimoHasher(algorithm: 'sha3-512');
        sha3Hasher.update(wotsPK);
        final sha3HashResult = sha3Hasher.digest(); // This will be 64 bytes

        final ripemdHasher = MochimoHasher(algorithm: 'ripemd160');
        ripemdHasher.update(sha3HashResult);
        final ripemdHashResult = ripemdHasher.digest(); // This will be 20 bytes

        final expectedAddr = Uint8List(WotsAddress.TXADDRLEN);
        expectedAddr.setAll(0, ripemdHashResult);
        // Fill the remaining part of the address by repeating the ripemdHashResult bytes
        int remainingLength = WotsAddress.TXADDRLEN - WotsAddress.ADDR_TAG_LEN;
        for (int i = 0; i < remainingLength; i++) {
          expectedAddr[WotsAddress.ADDR_TAG_LEN + i] =
              ripemdHashResult[i % ripemdHashResult.length];
        }

        final expectedAddrHex = ByteUtils.bytesToHex(expectedAddr);

        // print('Calculated Expected addr: $expectedAddrHex');
        // print('Actual addr from test: $finalAddrHex');

        expect(finalAddrHex.toLowerCase().trim(),
            equals(expectedAddrHex.toLowerCase().trim()));
      });
    });
  });
}

// Extension to simulate JavaScript's String.prototype.repeat
extension StringRepeat on String {
  String repeat(int count) {
    if (count < 0) {
      throw ArgumentError('Count cannot be negative');
    }
    final buffer = StringBuffer();
    for (int i = 0; i < count; i++) {
      buffer.write(this);
    }
    return buffer.toString();
  }
}
