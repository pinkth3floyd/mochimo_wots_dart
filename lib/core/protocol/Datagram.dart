import 'dart:typed_data';
import 'package:mochimo_wots/core/model/ByteBuffer.dart';
import 'package:mochimo_wots/core/utils/ByteUtils.dart' hide ByteArray;
import 'package:mochimo_wots/core/utils/CRC16.dart';
import 'package:meta/meta.dart';

/// Datagram constants
class DatagramConstants {
  static const int LENGTH = 8920;
  static const int TRANSACTION_BUFFER_LENGTH_OFFSET = 122;
  static const int TRANSACTION_BUFFER_LENGTH_LENGTH = 2;
  static const int TRANSACTION_BUFFER_OFFSET = 124;
  static const int TRANSACTION_BUFFER_LENGTH = 8792;
  static const int ADD_TO_PEER_LIST_TRANSACTION_BUFFER_LENGTH = 0;
  static const int DO_NOT_ADD_TO_PEER_LIST_TRANSACTION_BUFFER_LENGTH = 1;
}

/// Capability flags for datagram
enum Capability {
  push(7),
  wallet(6),
  sanctuary(5),
  mFee(4),
  logging(3);

  final int value;
  const Capability(this.value);
}

/// Operation enum
enum Operation {
  transaction(1),
  block(2),
  blockRequest(3),
  peerRequest(4),
  peerData(5),
  balanceRequest(6),
  balanceData(7);

  final int value;
  const Operation(this.value);
}

/// Datagram implementation
class Datagram {
  int _version = 4;
  List<bool> _flags = List.filled(8, false);
  int _network = 1337;
  int _id1 = 0;
  int _id2 = 0;
  Operation _operation = Operation.transaction;
  BigInt _cblock = BigInt.zero;
  BigInt _blocknum = BigInt.zero;
  Uint8List _cblockhash = Uint8List(32);
  Uint8List _pblockhash = Uint8List(32);
  Uint8List _weight = Uint8List(32);
  int _transactionBufferLength = 1;

  Uint8List _sourceAddress = Uint8List(2208);
  Uint8List _destinationAddress = Uint8List(2208);
  Uint8List _changeAddress = Uint8List(2208);

  Uint8List _totalSend = Uint8List(8);
  Uint8List _totalChange = Uint8List(8);
  Uint8List _fee = Uint8List(8);

  Uint8List _signature = Uint8List(2144);

  int? _crc;
  int _trailer = 43981;

  /// Serializes datagram to bytes
  ByteArray serialize() {
    if (_operation == null) {
      throw StateError('Operation not set');
    }

    final buffer = ByteBuffer.allocate(DatagramConstants.LENGTH);
    buffer.order(ByteOrder.LITTLE_ENDIAN);

    // Write version
    buffer.put(_version);

    // Write flags
    final flagBits = _flags.map((f) => f ? '1' : '0').join('');
    buffer.put(int.parse(flagBits, radix: 2));

    // Write network and IDs
    buffer.put(ByteUtils.numberToLittleEndian(_network, 2));
    buffer.put(ByteUtils.numberToLittleEndian(_id1, 2));
    buffer.put(ByteUtils.numberToLittleEndian(_id2, 2));
    buffer.put(ByteUtils.numberToLittleEndian(_operation.value, 2));

    // Write block info
    buffer.put(ByteUtils.numberToLittleEndian(_cblock.toInt(), 8));
    buffer.put(ByteUtils.numberToLittleEndian(_blocknum.toInt(), 8));
    buffer.put(_cblockhash);
    buffer.put(_pblockhash);
    buffer.put(_weight);
    buffer.put(ByteUtils.numberToLittleEndian(_transactionBufferLength, 2));

    // Write addresses
    buffer.put(_sourceAddress);
    buffer.put(_destinationAddress);
    buffer.put(_changeAddress);

    // Write amounts
    buffer.put(_totalSend);
    buffer.put(_totalChange);
    buffer.put(_fee);

    // Write signature
    buffer.put(_signature);

    // Calculate and write CRC
    final data = buffer.array();
    _crc = CRC16.crc(data, 0, 8916);
    buffer.put(ByteUtils.numberToLittleEndian(_crc!, 2));

    // Write trailer
    buffer.put(ByteUtils.numberToLittleEndian(_trailer, 2));

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
  Datagram setWeight(BigInt weight) {
    final bytes = ByteUtils.fit(weight.toString(), 32);
    _weight = ByteUtils.bytesToLittleEndian(bytes);
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

  /// Gets source address
  ByteArray getSourceAddress() => Uint8List.fromList(_sourceAddress);

  /// Sets source address
  Datagram setSourceAddress(ByteArray addr) {
    if (addr.length != 2208) {
      throw ArgumentError('Invalid address length');
    }
    _sourceAddress = Uint8List.fromList(addr);
    return this;
  }

  /// Gets destination address
  ByteArray getDestinationAddress() => Uint8List.fromList(_destinationAddress);

  /// Sets destination address
  Datagram setDestinationAddress(ByteArray addr) {
    if (addr.length != 2208) {
      throw ArgumentError('Invalid address length');
    }
    _destinationAddress = Uint8List.fromList(addr);
    return this;
  }

  /// Gets change address
  ByteArray getChangeAddress() => Uint8List.fromList(_changeAddress);

  /// Sets change address
  Datagram setChangeAddress(ByteArray addr) {
    if (addr.length != 2208) {
      throw ArgumentError('Invalid address length');
    }
    _changeAddress = Uint8List.fromList(addr);
    return this;
  }

  /// Gets total send amount
  ByteArray getTotalSend() => Uint8List.fromList(_totalSend);

  /// Sets total send amount
  Datagram setTotalSend(ByteArray amount) {
    if (amount.length != 8) {
      throw ArgumentError('Invalid amount length');
    }
    _totalSend = Uint8List.fromList(amount);
    return this;
  }

  /// Sets total send amount from bigint
  Datagram setTotalSendBigInt(BigInt amount) {
    _totalSend = ByteUtils.numberToLittleEndian(amount.toInt(), 8);
    return this;
  }

  /// Gets total change amount
  ByteArray getTotalChange() => Uint8List.fromList(_totalChange);

  /// Sets total change amount
  Datagram setTotalChange(ByteArray amount) {
    if (amount.length != 8) {
      throw ArgumentError('Invalid amount length');
    }
    _totalChange = Uint8List.fromList(amount);
    return this;
  }

  /// Sets total change amount from bigint
  Datagram setTotalChangeBigInt(BigInt amount) {
    _totalChange = ByteUtils.numberToLittleEndian(amount.toInt(), 8);
    return this;
  }

  /// Gets fee amount
  ByteArray getFee() => Uint8List.fromList(_fee);

  /// Sets fee amount
  Datagram setFee(ByteArray amount) {
    if (amount.length != 8) {
      throw ArgumentError('Invalid amount length');
    }
    _fee = Uint8List.fromList(amount);
    return this;
  }

  /// Sets fee amount from bigint
  Datagram setFeeBigInt(BigInt amount) {
    _fee = ByteUtils.numberToLittleEndian(amount.toInt(), 8);
    return this;
  }

  /// Gets signature
  ByteArray getSignature() => Uint8List.fromList(_signature);

  /// Sets signature
  Datagram setSignature(ByteArray sig) {
    if (sig.length != 2144) {
      throw ArgumentError('Invalid signature length');
    }
    _signature = Uint8List.fromList(sig);
    return this;
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

  /// Checks if should add to peer list
  bool isAddToPeerList() => _transactionBufferLength != 1;

  /// Sets add to peer list flag
  Datagram setAddToPeerList(bool value) {
    _transactionBufferLength = value ? 0 : 1;
    return this;
  }

  /// Gets version
  int getVersion() => _version;

  /// Creates a clone of this datagram
  Datagram clone() => Datagram.of(serialize());

  /// Creates datagram from bytes
  static Datagram of(ByteArray data) {
    if (data.length < DatagramConstants.LENGTH) {
      throw ArgumentError('Data length cannot be less than datagram length (${DatagramConstants.LENGTH})');
    }

    final buffer = ByteBuffer.allocate(DatagramConstants.LENGTH);
    buffer.order(ByteOrder.LITTLE_ENDIAN);
    buffer.put(data);
    buffer.rewind();

    final datagram = Datagram();

    // Read version and flags
    datagram._version = buffer.get_();
    final flag = buffer.get_();
    final bits = flag.toRadixString(2).padLeft(8, '0');
    datagram._flags = bits.split('').map((b) => b != '0').toList();

    // Read network and IDs using 2-byte values
    datagram._network = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();
    datagram._id1 = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();
    datagram._id2 = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();

    // Read operation
    final opCode = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();
    if (opCode == 0) {
      throw StateError('Invalid operation code 0');
    }
    datagram._operation = Operation.values.firstWhere((op) => op.value == opCode);

    // Read block info using 8-byte values
    datagram._cblock = ByteUtils.readLittleEndianUnsigned(buffer, 8);
    datagram._blocknum = ByteUtils.readLittleEndianUnsigned(buffer, 8);

    // Read hashes and weight
    buffer.get(datagram._cblockhash);
    buffer.get(datagram._pblockhash);
    buffer.get(datagram._weight);

    // Read transaction buffer length
    datagram._transactionBufferLength = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();

    // Read addresses
    buffer.get(datagram._sourceAddress);
    buffer.get(datagram._destinationAddress);
    buffer.get(datagram._changeAddress);

    // Read amounts
    buffer.get(datagram._totalSend);
    buffer.get(datagram._totalChange);
    buffer.get(datagram._fee);

    // Read signature
    buffer.get(datagram._signature);

    // Read CRC and trailer
    datagram._crc = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();
    datagram._trailer = ByteUtils.readLittleEndianUnsigned(buffer, 2).toInt();

    return datagram;
  }

  /// Parses capabilities from datagram
  static Set<Capability> parseCapabilities(Datagram datagram) {
    final capabilities = <Capability>{};
    for (final c in Capability.values) {
      if (datagram._flags[c.value]) {
        capabilities.add(c);
      }
    }
    return capabilities;
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

  /// Sets a capability flag (for testing)
  @visibleForTesting
  void setCapability(Capability capability, bool value) {
    _flags[capability.value] = value;
  }
}
