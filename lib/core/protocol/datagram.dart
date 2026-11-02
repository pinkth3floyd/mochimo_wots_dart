import 'dart:typed_data';
import 'package:mochimo_wots/core/model/byte_buffer.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart' hide ByteArray;
import 'package:mochimo_wots/core/utils/crc16.dart';

/// Framing constants for a Mochimo transaction PDU.
///
/// The header is 124 bytes, matching `TX_UP_TO_LEN`. The network id is
/// `0x3905` and is written big-endian (`39 05`). The trailer bytes are
/// `CD AB` (`TXTRAILER = 0xCDAB`).
class DatagramConstants {
  static const int headerLength = 124;
  static const int networkId = 0x3905;
  static const int trailer = 0xCDAB;
  static const int version = 4;
  static const int TRANSACTION_BUFFER_LENGTH_OFFSET = 122;
  static const int TRANSACTION_BUFFER_LENGTH_LENGTH = 2;
  static const int TRANSACTION_BUFFER_OFFSET = 124;
}

/// Opcodes from the node, `OP_NULL` through `OP_IDENTIFY`.
enum Operation {
  nullOp(0),
  hello(1),
  helloAck(2),
  transaction(3),
  found(4),
  getBlock(5),
  getIpList(6),
  sendFile(7),
  sendIpList(8),
  busy(9),
  nack(10),
  getTFile(11),
  balance(12),
  sendBalance(13),
  resolve(14),
  getCBlock(15),
  minedBlock(16),
  hash(17),
  trailerFile(18),
  identify(19);

  final int value;
  const Operation(this.value);
}

/// Datagram implementation
class Datagram {
  int _version = DatagramConstants.version;
  int _network = DatagramConstants.networkId;
  int _id1 = 0;
  int _id2 = 0;
  Operation _operation = Operation.transaction;
  BigInt _cblock = BigInt.zero;
  BigInt _blocknum = BigInt.zero;
  Uint8List _cblockhash = Uint8List(32);
  Uint8List _pblockhash = Uint8List(32);
  Uint8List _weight = Uint8List(32);
  int _transactionBufferLength = 0;
  Uint8List _payloadBytes = Uint8List(0);

  int? _crc;
  int _trailer = DatagramConstants.trailer;

  /// Replaces the PDU payload.
  ///
  /// A spend uses the bytes from `MochimoTransaction`. A balance query uses
  /// the 40-byte account address. The length is written as a 16-bit count.
  Datagram setPayload(ByteArray payload) {
    if (payload.length > 0xffff) {
      throw ArgumentError('Payload does not fit in the 16-bit length');
    }
    _payloadBytes = Uint8List.fromList(payload);
    _transactionBufferLength = _payloadBytes.length;
    return this;
  }

  /// Bytes that follow the 124-byte header.
  ByteArray getPayload() => Uint8List.fromList(_payloadBytes);

  /// Serializes the PDU: 124-byte header, payload, CRC-16, trailer.
  ByteArray serialize() {
    final payload = _payloadBytes;
    _transactionBufferLength = payload.length;
    final buffer = ByteBuffer.allocate(
        DatagramConstants.headerLength + payload.length + 4);
    buffer.order(ByteOrder.littleEndian);

    buffer.put(_version);
    buffer.put(0);

    // Network id is stored big-endian: bytes 0x39, 0x05.
    buffer.put((DatagramConstants.networkId >> 8) & 0xff);
    buffer.put(DatagramConstants.networkId & 0xff);
    buffer.put(ByteUtils.numberToLittleEndian(_id1, 2));
    buffer.put(ByteUtils.numberToLittleEndian(_id2, 2));
    buffer.put(ByteUtils.numberToLittleEndian(_operation.value, 2));

    // Write block info
    buffer.put(ByteUtils.numberToLittleEndian(_cblock.toInt(), 8));
    buffer.put(ByteUtils.numberToLittleEndian(_blocknum.toInt(), 8));
    buffer.put(_cblockhash);
    buffer.put(_pblockhash);
    buffer.put(_weight);
    buffer.put(ByteUtils.numberToLittleEndian(payload.length, 2));
    buffer.put(payload);

    final covered = DatagramConstants.headerLength + payload.length;
    _crc = CRC16.crc(buffer.array(), 0, covered);
    buffer.put(ByteUtils.numberToLittleEndian(_crc!, 2));
    buffer.put((DatagramConstants.trailer >> 8) & 0xff);
    buffer.put(DatagramConstants.trailer & 0xff);

    return buffer.array();
  }

  /// Gets the network ID
  int getNetwork() => _network;

  /// Gets the trailer
  int getTrailer() => _trailer;

  /// Gets ID1
  int getId1() => _id1;

  /// Sets ID1
  Datagram setId1(int id1) {
    _id1 = id1;
    return this;
  }

  /// Gets ID2
  int getId2() => _id2;

  /// Sets ID2
  Datagram setId2(int id2) {
    _id2 = id2;
    return this;
  }

  /// Gets operation
  Operation getOperation() => _operation;

  /// Sets operation
  Datagram setOperation(Operation operation) {
    _operation = operation;
    return this;
  }

  /// Gets current block height
  BigInt getCurrentBlockHeight() => _cblock;

  /// Sets current block height
  Datagram setCurrentBlockHeight(BigInt cblock) {
    _cblock = cblock;
    return this;
  }

  /// Sets current block hash
  Datagram setCurrentBlockHash(ByteArray hash) {
    if (hash.length != 32) throw ArgumentError('Invalid hash length');
    _cblockhash = Uint8List.fromList(hash);
    return this;
  }

  /// Sets previous block hash
  Datagram setPreviousBlockHash(ByteArray hash) {
    if (hash.length != 32) throw ArgumentError('Invalid hash length');
    _pblockhash = Uint8List.fromList(hash);
    return this;
  }

  /// Gets block number
  BigInt getBlocknum() => _blocknum;

  /// Sets block number
  Datagram setBlocknum(BigInt blocknum) {
    _blocknum = blocknum;
    return this;
  }

  /// Gets weight
  ByteArray getWeight() => Uint8List.fromList(_weight);

  /// Sets weight from bigint
  /// Stores [weight] as a 32-byte little-endian integer.
  Datagram setWeight(BigInt weight) {
    _weight = ByteUtils.fit(weight.toString(), 32);
    return this;
  }

  /// Sets weight from bytes
  Datagram setWeightBytes(ByteArray weight) {
    if (weight.length != 32) {
      throw ArgumentError('Invalid weight length');
    }
    _weight = Uint8List.fromList(weight);
    return this;
  }

  /// Gets CRC
  int getCRC() => _crc ?? 0;

  /// Asks for the ledger entry of a 40-byte account address.
  ///
  /// The node opcode is `OP_BALANCE`. A reply uses [Operation.sendBalance]
  /// and a 48-byte entry: the same address, then the balance as a
  /// little-endian 64-bit integer (`LENTRY` in `src/types.h`).
  static Datagram balanceQuery(ByteArray address) {
    if (address.length != 40) {
      throw ArgumentError('A balance query takes a 40-byte account address');
    }
    return Datagram()
      ..setOperation(Operation.balance)
      ..setPayload(address);
  }

  /// Reads an `OP_SEND_BAL` payload into an address and a balance.
  static ({Uint8List address, BigInt balance}) readLedgerEntry(
      ByteArray payload) {
    if (payload.length != 48) {
      throw ArgumentError('A ledger entry is 48 bytes');
    }
    var balance = BigInt.zero;
    for (var i = 47; i >= 40; i--) {
      balance = (balance << 8) | BigInt.from(payload[i]);
    }
    return (
      address: Uint8List.fromList(payload.sublist(0, 40)),
      balance: balance
    );
  }

  /// Gets previous block hash
  ByteArray getPblockhash() => Uint8List.fromList(_pblockhash);

  /// Gets current block hash
  ByteArray getCblockhash() => Uint8List.fromList(_cblockhash);

  /// Gets transaction buffer length
  int getTransactionBufferLength() => _transactionBufferLength;

  /// Sets transaction buffer length
  Datagram setTransactionBufferLength(int length) {
    _transactionBufferLength = length;
    return this;
  }

  /// Gets version
  int getVersion() => _version;

  /// Creates a clone of this datagram
  Datagram clone() => Datagram.of(serialize());

  /// Creates a datagram from a serialized PDU.
  static Datagram of(ByteArray data) {
    const minLength = DatagramConstants.headerLength + 4;
    if (data.length < minLength) {
      throw ArgumentError('Data length cannot be less than $minLength bytes');
    }

    final buffer = ByteBuffer.wrap(data);
    buffer.order(ByteOrder.littleEndian);

    final datagram = Datagram();

    datagram._version = buffer.get_();
    buffer.get_();
    final networkHi = buffer.get_();
    final networkLo = buffer.get_();
    datagram._network = (networkHi << 8) | networkLo;
    datagram._id1 = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();
    datagram._id2 = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();

    final opCode = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();
    datagram._operation = Operation.values.firstWhere(
      (op) => op.value == opCode,
      orElse: () => throw StateError('Invalid operation code $opCode'),
    );

    datagram._cblock = ByteUtils.readLittleEndianUnsigned(buffer, 8);
    datagram._blocknum = ByteUtils.readLittleEndianUnsigned(buffer, 8);

    buffer.get(datagram._cblockhash);
    buffer.get(datagram._pblockhash);
    buffer.get(datagram._weight);

    datagram._transactionBufferLength =
        ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();
    final payloadLength = datagram._transactionBufferLength;
    if (data.length < DatagramConstants.headerLength + payloadLength + 4) {
      throw ArgumentError(
          'Data length cannot hold a payload of $payloadLength bytes');
    }

    final payload = Uint8List(payloadLength);
    buffer.get(payload);
    datagram._payloadBytes = payload;

    datagram._crc = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();
    final trailerHi = buffer.get_();
    final trailerLo = buffer.get_();
    datagram._trailer = (trailerHi << 8) | trailerLo;

    return datagram;
  }

  /// Gets route as weight
  static ByteArray getRouteAsWeight(List<String> route) {
    final weight = Uint8List(32);
    var wi = 0;

    final startIndex = route.length > 8 ? route.length - 8 : 0;
    for (var i = startIndex; i < route.length; i++) {
      final ip = route[i].trim();
      final parts = ip.split('.');

      if (parts.length != 4) {
        throw ArgumentError('Invalid IP $ip');
      }

      for (final part in parts) {
        final value = int.parse(part);
        if (value < 0 || value > 255) {
          throw ArgumentError('Invalid byte $value');
        }
        weight[wi++] = value;
      }
    }

    return weight;
  }

  /// Parses transaction IPs from datagram
  static Set<String> parseTxIps(Datagram datagram) {
    final ips = <String>{};
    final weightBytes = datagram.getWeight();

    for (var i = 0; i < weightBytes.length; i += 4) {
      var zeros = 0;
      final parts = <int>[];

      for (var j = 0; j < 4; j++) {
        final b = weightBytes[i + j];
        if (b == 0) zeros++;
        if (zeros >= 4) break;
        parts.add(b);
      }

      if (zeros >= 4) break;
      ips.add(parts.join('.'));
    }

    return ips;
  }
}
