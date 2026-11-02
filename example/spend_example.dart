import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  final sourceSecret = Uint8List(32)..fillRange(0, 32, 0x11);
  final changeSecret = Uint8List(32)..fillRange(0, 32, 0x22);
  final source = WOTSWallet.create('source', sourceSecret);
  final change = WOTSWallet.create('change', changeSecret, source.getAddrTag());

  final destination = Uint8List(20)..fillRange(0, 20, 0x33);
  final spend = MochimoTransaction.sign(
    source: source,
    change: change,
    destinations: [
      TxDestination(tag: destination, amount: BigInt.from(1000), memo: 'AB-01'),
    ],
    changeAmount: BigInt.from(500),
    fee: BigInt.from(500),
  );

  final packet = Datagram()
    ..setOperation(Operation.transaction)
    ..setPayload(spend.bytes);
  final wire = packet.serialize();

  print('Account: ${ByteUtils.bytesToHex(spend.sourceAddress)}');
  print('Change: ${ByteUtils.bytesToHex(spend.changeAddressBytes)}');
  print('Transaction: ${spend.bytes.length} bytes');
  print('Packet: ${wire.length} bytes');
  print('Message: ${ByteUtils.bytesToHex(spend.messageHash())}');
}
