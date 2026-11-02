import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  final sourcePK = Uint8List(WOTS.WOTSSIGBYTES);
  final sourceSecret = Uint8List(32)..fillRange(0, 32, 0x56);
  final sourcePubSeed = Uint8List(32)..fillRange(0, 32, 0x12);
  final sourceRnd2 = Uint8List(32)..fillRange(0, 32, 0x34);

  print('Generating WOTS public key...');
  WOTS.wotsPkgen(sourcePK, sourceSecret, sourcePubSeed, 0, sourceRnd2);

  // 2144-byte public key, 32-byte public seed, 32-byte address seed.
  final sourceAddress = Uint8List(2208);
  sourceAddress.setRange(0, WOTS.WOTSSIGBYTES, sourcePK);
  sourceAddress.setRange(
      WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32, sourcePubSeed);
  sourceAddress.setRange(2176, 2208, sourceRnd2);

  // The node writes 0x42, 0x0e, 0x01 into the last 12 bytes when it publishes.
  WOTS.stampAddressSuffix(sourceAddress);

  print(
      'Public key (first 32 bytes): ${ByteUtils.bytesToHex(sourcePK.sublist(0, 32))}...');
  print('Public seed: ${ByteUtils.bytesToHex(sourcePubSeed)}');
  print('Address seed: ${ByteUtils.bytesToHex(sourceRnd2)}');
  print(
      'Published suffix: ${ByteUtils.bytesToHex(sourceAddress.sublist(2196))}');

  // The ledger address is 40 bytes, not the 12-byte WOTS suffix.
  final account = WotsAddress.wotsAddressFromBytes(sourcePK);
  print('Account address: ${ByteUtils.bytesToHex(account.getAddress())}');
  print('Account tag: ${TagUtils.addrTagToBase58(account.getTag())}');

  // Tag.tag replaces that published suffix. It is not the 20-byte account tag.
  final suffix = Uint8List(Tag.TAG_LENGTH)..fillRange(0, Tag.TAG_LENGTH, 0x12);
  final tagged = Tag.tag(sourceAddress, suffix);
  print('Custom WOTS suffix: ${ByteUtils.bytesToHex(tagged.sublist(2196))}');
}
