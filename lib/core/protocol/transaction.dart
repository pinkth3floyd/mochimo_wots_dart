import 'dart:typed_data';

import 'package:mochimo_wots/core/hasher/mochimo_hasher.dart';
import 'package:mochimo_wots/core/protocol/wots.dart';
import 'package:mochimo_wots/core/protocol/wots_address.dart';
import 'package:mochimo_wots/core/protocol/wots_wallet.dart';

/// One recipient in a Mochimo transaction.
///
/// The on-wire entry is 44 bytes: a 20-byte tag, a 16-byte reference, and an
/// 8-byte little-endian amount. That is `MDST` in `src/types.h`.
class TxDestination {
  final Uint8List tag;
  final Uint8List reference;
  final BigInt amount;

  TxDestination({
    required Uint8List tag,
    required this.amount,
    Uint8List? reference,
    String? memo,
  })  : tag = Uint8List.fromList(tag),
        reference = memo != null
            ? TxDestination.encodeMemo(memo)
            : Uint8List.fromList(reference ?? Uint8List(16));

  /// Encodes a memo into the 16-byte reference field.
  ///
  /// The text uses `A-Z`, `0-9`, and `-`, and the unused bytes are zero.
  /// Groups of letters and groups of digits must alternate.
  static Uint8List encodeMemo(String memo) {
    if (memo.length > 16) {
      throw ArgumentError('A reference is at most 16 bytes');
    }
    final out = Uint8List(16);
    out.setRange(0, memo.length, memo.codeUnits);
    if (!isValidReference(out)) {
      throw ArgumentError('Invalid reference "$memo"');
    }
    return out;
  }

  /// The node's reference state machine from `mdst_val__reference`.
  static bool isValidReference(Uint8List reference) {
    if (reference.length != 16) return false;
    var state = _RefState.start;
    for (final c in reference) {
      switch (state) {
        case _RefState.start:
          if (c == 0) {
            state = _RefState.zero;
          } else if (_isDigit(c)) {
            state = _RefState.digit;
          } else if (_isUpper(c)) {
            state = _RefState.upper;
          } else {
            return false;
          }
        case _RefState.digitDash:
          if (_isUpper(c)) {
            state = _RefState.upper;
          } else {
            return false;
          }
        case _RefState.upperDash:
          if (_isDigit(c)) {
            state = _RefState.digit;
          } else {
            return false;
          }
        case _RefState.digit:
          if (_isDigit(c)) {
            break;
          } else if (c == 0x2d) {
            state = _RefState.digitDash;
          } else if (c == 0) {
            state = _RefState.zero;
          } else {
            return false;
          }
        case _RefState.upper:
          if (_isUpper(c)) {
            break;
          } else if (c == 0x2d) {
            state = _RefState.upperDash;
          } else if (c == 0) {
            state = _RefState.zero;
          } else {
            return false;
          }
        case _RefState.zero:
          if (c != 0) return false;
      }
    }
    if (state == _RefState.zero ||
        state == _RefState.digit ||
        state == _RefState.upper) {
      return true;
    }
    return false;
  }

  Uint8List toBytes() {
    final out = Uint8List(MochimoTransaction.destinationLength);
    out.setRange(0, 20, tag);
    out.setRange(20, 36, reference);
    out.setRange(36, 44, MochimoTransaction.uint64(amount));
    return out;
  }
}

enum _RefState { start, digitDash, digit, upperDash, upper, zero }

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

bool _isUpper(int c) => c >= 0x41 && c <= 0x5a;

/// A transaction entry the node can validate.
///
/// The bytes are `TXHDR` (116) plus one `MDST` (44) per recipient plus
/// `WOTSVAL` (2208). The trailer is left off, which is the form `tx_bot`
/// submits: `TXLEN_MIN` for one recipient. The signed message is the SHA-256
/// of the header and the recipients, stopping where the signature begins.
class MochimoTransaction {
  static const int headerLength = 116;
  static const int destinationLength = 44;
  static const int wotsValueLength = 2208;
  static const int minimumLength =
      headerLength + destinationLength + wotsValueLength;

  final Uint8List bytes;

  MochimoTransaction(this.bytes);

  /// Signs a spend from [source].
  ///
  /// [change] is the next one-time key. Its public key becomes the change
  /// address, under the same 20-byte account tag as [source]. The source and
  /// change hashes must differ, and a destination tag must differ from the
  /// source tag. Those are checks in `tx_val`.
  factory MochimoTransaction.sign({
    required WOTSWallet source,
    required WOTSWallet change,
    required List<TxDestination> destinations,
    required BigInt changeAmount,
    required BigInt fee,
    BigInt? blockToLive,
  }) {
    final secret = source.getSecret();
    final wots = source.getWots();
    final tag = source.getAddrTag();
    final next = change.getWots();
    if (secret == null || wots == null || tag == null || next == null) {
      throw StateError(
          'Source and change wallets need a key and an account tag');
    }
    return MochimoTransaction.signWithKey(
      signingSeed: secret,
      sourceWots: wots,
      accountTag: tag,
      changeAddress: changeAddress(tag, next.sublist(0, WOTS.WOTSSIGBYTES)),
      destinations: destinations,
      changeAmount: changeAmount,
      fee: fee,
      blockToLive: blockToLive,
    );
  }

  /// 40-byte change address: [accountTag] followed by the hash of [publicKey].
  static Uint8List changeAddress(Uint8List accountTag, Uint8List publicKey) {
    if (accountTag.length != WotsAddress.ADDR_TAG_LEN) {
      throw ArgumentError('Invalid account tag');
    }
    final hash = WotsAddress.addrHashGenerate(publicKey);
    final address = Uint8List(WotsAddress.TXADDRLEN);
    address.setRange(0, 20, accountTag);
    address.setRange(20, 40, hash);
    return address;
  }

  factory MochimoTransaction.signWithKey({
    required Uint8List signingSeed,
    required Uint8List sourceWots,
    required Uint8List accountTag,
    required Uint8List changeAddress,
    required List<TxDestination> destinations,
    required BigInt changeAmount,
    required BigInt fee,
    BigInt? blockToLive,
  }) {
    if (signingSeed.length != 32) {
      throw ArgumentError('Invalid signing seed');
    }
    if (sourceWots.length != 2208) {
      throw ArgumentError('Invalid WOTS address');
    }
    if (accountTag.length != 20 || changeAddress.length != 40) {
      throw ArgumentError('Invalid address');
    }
    if (destinations.isEmpty || destinations.length > 256) {
      throw ArgumentError('A transaction needs 1 to 256 destinations');
    }

    final publicKey = sourceWots.sublist(0, WOTS.WOTSSIGBYTES);
    final sourceHash = WotsAddress.addrHashGenerate(publicKey);
    final sourceAddress = Uint8List(40);
    sourceAddress.setRange(0, 20, accountTag);
    sourceAddress.setRange(20, 40, sourceHash);

    if (!_sameBytes(accountTag, changeAddress.sublist(0, 20))) {
      throw ArgumentError('Change address must use the source account tag');
    }
    if (_sameBytes(sourceHash, changeAddress.sublist(20))) {
      throw ArgumentError(
          'Change address hash must differ from the source hash');
    }

    final entries = <Uint8List>[];
    for (final destination in destinations) {
      if (destination.tag.length != 20) {
        throw ArgumentError('Invalid destination tag');
      }
      if (_sameBytes(destination.tag, accountTag)) {
        throw ArgumentError(
            'A destination tag must differ from the source tag');
      }
      if (destination.amount <= BigInt.zero) {
        throw ArgumentError('A destination amount must be greater than zero');
      }
      if (!TxDestination.isValidReference(destination.reference)) {
        throw ArgumentError('Invalid destination reference');
      }
      entries.add(destination.toBytes());
    }
    entries.sort(_compareBytes);

    var sendTotal = BigInt.zero;
    for (final destination in destinations) {
      sendTotal += destination.amount;
    }

    final count = entries.length;
    final signedLength = headerLength + destinationLength * count;
    final body = Uint8List(signedLength + wotsValueLength);
    body[0] = 0; // TXDAT_MDST
    body[1] = 0; // TXDSA_WOTS
    body[2] = count - 1;
    body.setRange(4, 44, sourceAddress);
    body.setRange(44, 84, changeAddress);
    body.setRange(84, 92, uint64(sendTotal));
    body.setRange(92, 100, uint64(changeAmount));
    body.setRange(100, 108, uint64(fee));
    body.setRange(108, 116, uint64(blockToLive ?? BigInt.zero));
    var offset = headerLength;
    for (final entry in entries) {
      body.setRange(offset, offset + destinationLength, entry);
      offset += destinationLength;
    }

    final message = MochimoHasher.hash(body.sublist(0, signedLength));
    final publicSeed =
        sourceWots.sublist(WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32);
    final addressSeed = Uint8List.fromList(
        sourceWots.sublist(WOTS.WOTSSIGBYTES + 32, WOTS.WOTSSIGBYTES + 64));
    final signature = Uint8List(WOTS.WOTSSIGBYTES);
    WOTS.wotsSign(signature, message, signingSeed, publicSeed, 0, addressSeed);

    final recovered =
        WOTS.wotsPkFromSig(signature, message, publicSeed, addressSeed);
    if (!_sameBytes(recovered, publicKey)) {
      // Reached only when this library signs a key it cannot verify.
      throw StateError(// coverage:ignore-line
          'WOTS signature does not recover the source public key'); // coverage:ignore-line
    }

    // tx.c stamps the published address seed after signing.
    WOTS.stampAddressSuffix(addressSeed);
    body.setRange(signedLength, signedLength + WOTS.WOTSSIGBYTES, signature);
    body.setRange(signedLength + WOTS.WOTSSIGBYTES,
        signedLength + WOTS.WOTSSIGBYTES + 32, publicSeed);
    body.setRange(
        signedLength + WOTS.WOTSSIGBYTES + 32, body.length, addressSeed);
    return MochimoTransaction(body);
  }

  /// SHA-256 of the header and destinations. This is `TX_HASH_MESSAGE`.
  Uint8List messageHash() {
    return MochimoHasher.hash(bytes.sublist(0, signatureOffset));
  }

  int get destinationCount => bytes[2] + 1;

  int get signatureOffset =>
      headerLength + destinationLength * destinationCount;

  Uint8List get sourceAddress => bytes.sublist(4, 44);

  Uint8List get changeAddressBytes => bytes.sublist(44, 84);

  Uint8List get signature =>
      bytes.sublist(signatureOffset, signatureOffset + WOTS.WOTSSIGBYTES);

  /// Little-endian unsigned 64-bit integer, matching `put64`.
  static Uint8List uint64(BigInt value) {
    if (value.isNegative || value.bitLength > 64) {
      throw ArgumentError('Amount does not fit in 8 bytes');
    }
    final out = Uint8List(8);
    var rest = value;
    for (var i = 0; i < 8; i++) {
      out[i] = (rest & BigInt.from(0xff)).toInt();
      rest >>= 8;
    }
    return out;
  }

  static BigInt readUint64(Uint8List bytes, int offset) {
    var value = BigInt.zero;
    for (var i = 7; i >= 0; i--) {
      value = (value << 8) | BigInt.from(bytes[offset + i]);
    }
    return value;
  }
}

int _compareBytes(Uint8List a, Uint8List b) {
  final length = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    final diff = a[i] - b[i];
    if (diff != 0) return diff;
  }
  return a.length - b.length;
}

bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
