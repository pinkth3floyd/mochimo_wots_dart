# Changelog

## 2.0.0

Signatures and account addresses now follow the current Mochimo node.

- WOTS+ key generation, signing, and verification match `src/wots.c`: the seed expands with a 32-byte big-endian counter, and the address seed is eight little-endian words serialized big-endian into the hash.
- Account tags are 20 bytes. An implicit address is that tag copied into both halves of the 40-byte address, with the tag equal to `RIPEMD160(SHA3-512(public key))`.
- Base58 tags are the 20-byte tag plus a CRC-16/XMODEM checksum.
- `WOTSWallet.create` derives the signing seed once. `sign` accepts a 32-byte digest, and hashes any other message with SHA-256.
- Datagrams use the 124-byte PDU header: version 4, network `0x3905`, node opcodes, a real payload length, CRC-16, and trailer `0xCDAB`. The transaction payload is a node `TXENTRY` without the trailer: a 116-byte header, 44-byte destinations, and a 2208-byte WOTS signature.
- The package is pure Dart. The Flutter SDK is no longer a dependency.

## 0.1.0

Initial release with the following features:

- Implemented WOTS wallet functionality
- Added Datagram protocol implementation
- Included ByteBuffer for byte manipulation
- Added utility functions for cryptographic operations
- Implemented CRC16 checksum calculation
- Added comprehensive test suite
