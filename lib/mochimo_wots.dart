/// A Dart implementation of the Mochimo WOTS+ protocol.
///
/// The cryptographic routines follow `src/wots.c` in the Mochimo node:
/// WOTS+ with `n = 32` and `w = 16`, SHA-256 as the chain hash, and the
/// 2208-byte address layout (2144-byte public key, 32-byte public seed,
/// 32-byte address seed).
///
/// Account addresses are 40 bytes: a 20-byte tag and a 20-byte hash.
/// An implicit account uses `RIPEMD160(SHA3-512(public key))` for both halves.
///
/// * [WOTS] signs and verifies 32-byte digests.
/// * [WOTSWallet] derives a key and an account tag from a secret.
/// * [WotsAddress] is the 40-byte ledger address.
/// * [Datagram] is the 124-byte network PDU. Its payload is a transaction,
///   a balance query, or another node request.
/// * [MochimoTransaction] is the spend the node validates.
/// * [TagUtils] encodes a 20-byte tag as Base58 with a CRC-16 checksum.
library;

export 'core/hasher/mochimo_hasher.dart' hide ByteArray;
export 'core/model/byte_buffer.dart' hide HexString, ByteArray, Byte, BigIntD;
export 'core/protocol/datagram.dart';
export 'core/protocol/tags.dart';
export 'core/protocol/transaction.dart';
export 'core/protocol/wots.dart';
export 'core/protocol/wots_address.dart' hide ByteArray;
export 'core/protocol/wots_hash.dart' hide ByteArray;
export 'core/protocol/wots_wallet.dart';
export 'core/utils/byte_utils.dart' hide ByteArray, HexString;
export 'core/utils/crc16.dart';
export 'core/utils/tag_utils.dart' hide ByteArray;
