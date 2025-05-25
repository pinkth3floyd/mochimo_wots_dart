import 'dart:typed_data';
import 'package:mochimo_wots/mochimo_wots.dart';

void main() {
  print('ByteBuffer Operations Example\n');

  // Create a new buffer with 1024 bytes capacity
  final buffer = ByteBuffer.allocate(1024);
  print('Created buffer with capacity: 1024 bytes');

  // Write different types of data
  buffer.order(ByteOrder.LITTLE_ENDIAN)
        .putInt(0x12345678)  // Write an integer
        .putLong(0x1234567890ABCDEF)  // Write a long
        .put(Uint8List.fromList([1, 2, 3, 4]))  // Write bytes
        .putShort(0x1234);  // Write a short

  print('\nWrote to buffer:');
  print('- Integer: 0x12345678');
  print('- Long: 0x1234567890ABCDEF');
  print('- Bytes: [1, 2, 3, 4]');
  print('- Short: 0x1234');

  // Read data back
  buffer.rewind();  // Reset position to start
  print('\nReading back data:');

  // Read and print integer
  final readInt = buffer.getInt();
  print('Read integer: 0x${readInt.toRadixString(16).padLeft(8, '0')}');

  // Read and print long
  final readLong = buffer.getLong();
  print('Read long: 0x${readLong.toRadixString(16).padLeft(16, '0')}');

  // Read bytes
  final readBytes = Uint8List(4);
  buffer.get(readBytes);
  print('Read bytes: [${readBytes.join(', ')}]');

  // Read short
  final readShort = buffer.getShort();
  print('Read short: 0x${readShort.toRadixString(16).padLeft(4, '0')}');

  // Demonstrate position and limit
  print('\nBuffer state:');
  print('Position: ${buffer.position()}');
  print('Limit: ${buffer.limit()}');
  print('Capacity: ${buffer.capacity()}');

  // Demonstrate mark and reset
  buffer.rewind();
  buffer.getInt();  // Read the first integer
  buffer.mark();    // Mark this position
  buffer.getInt();  // Read more data
  buffer.reset();   // Reset to marked position
  
  print('\nDemonstrating mark/reset:');
  print('After reset, next int: 0x${buffer.getLong().toRadixString(16)}');
} 