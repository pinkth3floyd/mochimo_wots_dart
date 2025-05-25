import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';
import 'package:mochimo_wots/core/utils/byte_utils.dart';

void main() {
  print('ByteBuffer Operations Example\n');

  // Create a new buffer with 32 bytes capacity
  final buffer = ByteBuffer.allocate(32);
  print('Created buffer with capacity: ${buffer.capacity()} bytes');

  // Demonstrate byte order settings
  print('\nDemonstrating byte order settings:');
  
  // Write an integer in big-endian
  buffer.order(ByteOrder.BIG_ENDIAN);
  buffer.putInt(0x12345678);
  print('Wrote integer in big-endian: 0x12345678');
  
  // Write an integer in little-endian
  buffer.order(ByteOrder.LITTLE_ENDIAN);
  buffer.putInt(0x9ABCDEF0);
  print('Wrote integer in little-endian: 0x9ABCDEF0');

  // Write some individual bytes
  final bytes = Uint8List.fromList([1, 2, 3, 4]);
  buffer.put(bytes);
  print('Wrote bytes: [${bytes.join(', ')}]');

  // Demonstrate position management
  print('\nBuffer position management:');
  print('Current position: ${buffer.position()}');
  
  // Rewind and read back the data
  buffer.rewind();
  print('\nReading back data:');

  // Read first integer (big-endian)
  buffer.order(ByteOrder.BIG_ENDIAN);
  final readInt1 = _readIntFromBuffer(buffer, ByteOrder.BIG_ENDIAN);
  print('Read big-endian integer: 0x${readInt1.toRadixString(16).padLeft(8, '0')}');

  // Read second integer (little-endian)
  buffer.order(ByteOrder.LITTLE_ENDIAN);
  final readInt2 = _readIntFromBuffer(buffer, ByteOrder.LITTLE_ENDIAN);
  print('Read little-endian integer: 0x${readInt2.toRadixString(16).padLeft(8, '0')}');

  // Read bytes
  final readBytes = Uint8List(4);
  buffer.get(readBytes);
  print('Read bytes: [${readBytes.join(', ')}]');

  // Demonstrate ByteUtils functionality
  print('\nDemonstrating ByteUtils functionality:');
  
  // Convert bytes to hex
  final hexString = ByteUtils.bytesToHex(bytes);
  print('Bytes to hex: $hexString');

  // Convert hex back to bytes
  final convertedBytes = ByteUtils.hexToBytes(hexString);
  print('Hex to bytes: [${convertedBytes.join(', ')}]');

  // Demonstrate byte array comparison
  final areEqual = ByteUtils.areEqual(bytes, convertedBytes);
  print('Bytes are equal: $areEqual');

  // Show current buffer state
  print('\nFinal buffer state:');
  print('Position: ${buffer.position()}');
  print('Capacity: ${buffer.capacity()}');
}

// Helper function to read an int from the buffer using get_()
int _readIntFromBuffer(ByteBuffer buffer, ByteOrder order) {
  final b1 = buffer.get_();
  final b2 = buffer.get_();
  final b3 = buffer.get_();
  final b4 = buffer.get_();
  
  if (order == ByteOrder.BIG_ENDIAN) {
    return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
  } else {
    return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
  }
} 