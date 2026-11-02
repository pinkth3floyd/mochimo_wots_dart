import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  print('WOTS Wallet Example\n');

  final secret = Uint8List(32)..fillRange(0, 32, 0x56);
  final tag = Uint8List(WotsAddress.ADDR_TAG_LEN)..fillRange(0, 20, 0x34);

  print('Secret: ${ByteUtils.bytesToHex(secret)}');
  print('Account tag: ${ByteUtils.bytesToHex(tag)}');

  final wallet = WOTSWallet.create('Test Wallet', secret, tag);
  final address = wallet.getAddress();
  final wots = wallet.getWots();
  final signingSecret = wallet.getSecret();
  if (address == null || wots == null || signingSecret == null) {
    print('Wallet is missing an address or signing seed');
    return;
  }

  print('Name: ${wallet.getName()}');
  print('Account address (40 bytes): ${ByteUtils.bytesToHex(address)}');
  print('Account tag: ${wallet.getAddrTagHex()}');
  print('Base58 tag: ${wallet.getAddrTagBase58()}');
  print('WOTS blob: ${wots.length} bytes');
  print('Published suffix: ${ByteUtils.bytesToHex(wallet.getWotsTag()!)}');
  print(
      'Account tag matches: ${ByteUtils.areEqual(tag, wallet.getAddrTag()!)}');

  // create() stores the derived signing seed. Validation uses that seed.
  final isValid = WOTS.isValid(signingSecret, wots);
  print('WOTS address valid: $isValid');
}
