import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  final account = Uint8List(40)..fillRange(0, 40, 0x11);
  final query = Datagram.balanceQuery(account);
  final bytes = query.serialize();
  final parsed = Datagram.of(bytes);

  print('Opcode: ${parsed.getOperation()}');
  print('Version: ${parsed.getVersion()}');
  print('Network: 0x${parsed.getNetwork().toRadixString(16)}');
  print('Trailer: 0x${parsed.getTrailer().toRadixString(16)}');
  print('Frame: ${bytes.length} bytes');
  print('Asked for: ${ByteUtils.bytesToHex(parsed.getPayload())}');

  final reply = Uint8List(48);
  reply.setRange(0, 40, account);
  reply[40] = 0xe8;
  reply[41] = 0x03;
  final ledger = Datagram.readLedgerEntry(reply);
  print('Balance: ${ledger.balance}');
}
