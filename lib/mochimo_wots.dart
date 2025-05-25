/// A Dart implementation of the Mochimo WOTS (Winternitz One-Time Signature) protocol.
///
/// This library provides cryptographic functionality for the Mochimo cryptocurrency network,
/// including WOTS signature generation and verification, address generation, and network
/// protocol implementations.
///
/// The main components of this library are:
/// * [WotsWallet] - Implementation of the WOTS wallet functionality
/// * [Datagram] - Network protocol implementation for Mochimo
/// * [ByteBuffer] - Utility class for byte manipulation
/// * [ByteUtils] - Helper functions for byte operations
/// * [CRC16] - CRC checksum calculation utilities
library mochimo_wots;

export 'core/model/byte_buffer.dart';
export 'core/protocol/datagram.dart';
export 'core/protocol/wots_wallet.dart';
export 'core/utils/byte_utils.dart' hide ByteArray;
export 'core/utils/crc16.dart';

