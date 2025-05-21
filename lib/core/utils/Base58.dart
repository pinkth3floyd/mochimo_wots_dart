// import 'dart:typed_data';

// /// Base58 encoding/decoding compatible with JavaScript 'bs58' package
// class Base58 {
//   static const String _alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
//   static final Map<String, int> _alphabetMap = {
//     for (int i = 0; i < _alphabet.length; i++) _alphabet[i]: i
//   };

//   /// Encodes bytes to a Base58 string
//   static String encode(Uint8List bytes) {
//     if (bytes.isEmpty) return '';

//     BigInt intData = BigInt.zero;
//     for (final byte in bytes) {
//       intData = (intData << 8) | BigInt.from(byte);
//     }

//     final StringBuffer result = StringBuffer();

//     while (intData > BigInt.zero) {
//       final mod = intData.remainder(BigInt.from(58));
//       intData = intData ~/ BigInt.from(58);
//       result.write(_alphabet[mod.toInt()]);
//     }

//     // Deal with leading zeros
//     for (final byte in bytes) {
//       if (byte == 0) {
//         result.write(_alphabet[0]);
//       } else {
//         break;
//       }
//     }

//     return result.toString().split('').reversed.join('');
//   }

//   /// Decodes a Base58 string to bytes
//   static Uint8List decode(String input) {
//     if (input.isEmpty) return Uint8List(0);

//     BigInt intData = BigInt.zero;
//     for (final char in input.split('')) {
//       final digit = _alphabetMap[char];
//       if (digit == null) {
//         throw FormatException('Invalid Base58 character: $char');
//       }
//       intData = intData * BigInt.from(58) + BigInt.from(digit);
//     }

//     // Convert BigInt to bytes
//     final bytes = <int>[];
//     while (intData > BigInt.zero) {
//       bytes.insert(0, (intData & BigInt.from(0xff)).toInt());
//       intData = intData >> 8;
//     }

//     // Deal with leading zeros
//     for (final char in input.split('')) {
//       if (char == _alphabet[0]) {
//         bytes.insert(0, 0);
//       } else {
//         break;
//       }
//     }

//     return Uint8List.fromList(bytes);
//   }
// }
