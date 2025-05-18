import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:mochimo_wots/core/model/ByteBuffer.dart';

void main() {
  group('ByteBuffer', () {
    late ByteBuffer buffer;

    setUp(() {
      // Create a new buffer with some initial data
      buffer = ByteBuffer.wrap(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]));
    });

    group('creation', () {
      test('should create empty buffer with specified capacity', () {
        final buf = ByteBuffer.allocate(10);
        expect(buf.capacity(), 10);
        expect(buf.array(), Uint8List(10));
      });

      test('should create buffer wrapping existing array', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final buf = ByteBuffer.wrap(data);
        expect(buf.array(), data);
      });
    });

    group('position operations', () {
      test('should get current position', () {
        expect(buffer.position(), 0);
      });

      test('should set position', () {
        buffer.position(3);
        expect(buffer.position(), 3);
      });

      test('should throw error when setting invalid position', () {
        expect(() => buffer.position(-1), throwsA(isA<RangeError>()));
        expect(() => buffer.position(9), throwsA(isA<RangeError>()));
      });

      test('should be chainable when setting position', () {
        final result = buffer.position(3);
        expect(result, buffer);
      });
    });

    group('byte order operations', () {
      test('should set byte order', () {
        final result = buffer.order(ByteOrder.LITTLE_ENDIAN);
        expect(result, buffer);
      });
    });

    group('put operations', () {
      test('should put single byte', () {
        buffer.put(42);
        expect(buffer.array()[0], 42);
        expect(buffer.position(), 1);
      });

      test('should put bytes from array', () {
        final src = Uint8List.fromList([42, 43, 44]);
        buffer.put(src);
        expect(buffer.array().sublist(0, 3), src);
        expect(buffer.position(), 3);
      });

      test('should put bytes with offset and length', () {
        final src = Uint8List.fromList([42, 43, 44, 45, 46]);
        buffer.put(src, 1, 3);
        expect(buffer.array().sublist(0, 3), Uint8List.fromList([43, 44, 45]));
        expect(buffer.position(), 3);
      });

      test('should throw when putting past capacity', () {
        buffer.position(7);
        expect(() => buffer.put(Uint8List.fromList([1, 2])),
            throwsA(isA<RangeError>()));
      });
    });

    group('putInt operations', () {
      test('should put integer in big-endian order', () {
        buffer.order(ByteOrder.BIG_ENDIAN).putInt(0x12345678);
        expect(buffer.array().sublist(0, 4),
            Uint8List.fromList([0x12, 0x34, 0x56, 0x78]));
        expect(buffer.position(), 4);
      });

      test('should put integer in little-endian order', () {
        buffer.order(ByteOrder.LITTLE_ENDIAN).putInt(0x12345678);
        expect(buffer.array().sublist(0, 4),
            Uint8List.fromList([0x78, 0x56, 0x34, 0x12]));
        expect(buffer.position(), 4);
      });

      test('should throw when putting int past capacity', () {
        buffer.position(6);
        expect(() => buffer.putInt(1), throwsA(isA<RangeError>()));
      });
    });

    group('get operations', () {
      test('should get bytes into provided array', () {
        final dst = Uint8List(3);
        buffer.get(dst);
        expect(dst, Uint8List.fromList([1, 2, 3]));
        expect(buffer.position(), 3);
      });

      test('should throw when getting past capacity', () {
        buffer.position(6);
        expect(() => buffer.get(Uint8List(3)), throwsA(isA<RangeError>()));
      });
    });

    group('get_ operations', () {
      test('should get single byte', () {
        expect(buffer.get_(), 1);
        expect(buffer.position(), 1);
      });

      test('should throw when getting past capacity', () {
        buffer.position(8);
        expect(() => buffer.get_(), throwsA(isA<RangeError>()));
      });
    });

    group('array', () {
      test('should return copy of buffer contents', () {
        final arr = buffer.array();
        expect(arr, Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]));
        // Verify it's a copy
        arr[0] = 42;
        expect(buffer.array()[0], 1);
      });
    });

    group('rewind', () {
      test('should reset position to zero', () {
        buffer.position(4);
        final result = buffer.rewind();
        expect(buffer.position(), 0);
        expect(result, buffer);
      });
    });
  });
}
