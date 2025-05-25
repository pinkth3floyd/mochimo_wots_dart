import 'dart:typed_data';
import 'package:mochimo_wots/core/model/ByteBuffer.dart'; 

/**
 * Tag implementation for Mochimo addresses
 */
class Tag {
  static const int TAG_LENGTH = 12; 

  // Private constructor to prevent instantiation of a utility class
  Tag._();

  /**
   * Gets the tag from an address byte array.
   * The tag is the last TAG_LENGTH bytes of the address.
   *
   * @param address The address byte array (expected length: 2208).
   * @returns A copy of the tag as a ByteArray (Uint8List).
   * @throws ArgumentError if the address length is invalid.
   */
  static ByteArray getTag(ByteArray address) {
    if (address.length != 2208) {
      throw ArgumentError('Invalid address length: ${address.length}. Expected 2208.');
    }
    // Return a copy of the tag, which is the last TAG_LENGTH bytes
    return address.sublist(address.length - TAG_LENGTH);
  }

  /**
   * Checks if a tag byte array consists of all zeros.
   *
   * @param tag The tag byte array.
   * @returns True if the tag is all zeros and has the correct length, false otherwise.
   */
  static bool isZero(ByteArray? tag) {
    if (tag == null || tag.length != TAG_LENGTH) {
      return false;
    }
    // Use the 'every' method to check if all bytes are 0
    return tag.every((b) => b == 0);
  }

  /**
   * Validates a tag byte array.
   * Currently, it only checks if the tag is not null and has the correct length.
   *
   * @param tag The tag byte array.
   * @returns True if the tag is valid, false otherwise.
   */
  static bool isValid(ByteArray? tag) {
    if (tag == null || tag.length != TAG_LENGTH) {
      return false;
    }
    return true;
  }

  /**
   * Tags an address with the specified tag.
   * This function creates a new byte array which is a copy of the original address
   * with the tag bytes set at the end.
   *
   * @param address The original address byte array (expected length: 2208).
   * @param tag The tag byte array (expected length: TAG_LENGTH, i.e., 12).
   * @returns A new ByteArray (Uint8List) representing the tagged address.
   * @throws ArgumentError if the tag or address lengths are invalid.
   */
  static ByteArray tag(ByteArray address, ByteArray tag) {
    // Validate the tag first
    if (!isValid(tag)) {
      throw ArgumentError('Invalid tag provided. Tag must be non-null and have length ${TAG_LENGTH}.');
    }
    // Validate the address length
    if (address.length != 2208) {
      throw ArgumentError('Invalid address length: ${address.length}. Expected 2208.');
    }
    // Validate tag length (redundant if isValid is called, but good for clarity)
    if (tag.length != TAG_LENGTH) {
      throw ArgumentError('Invalid tag length: ${tag.length}. Expected ${TAG_LENGTH}.');
    }

    // Create a new Uint8List as a copy of the original address
    final tagged = Uint8List.fromList(address);
    // Set the tag bytes at the end of the copied address
    // The starting index for setting the tag is (total_length - tag_length)
    tagged.setAll(tagged.length - tag.length, tag);
    return tagged;
  }
}
