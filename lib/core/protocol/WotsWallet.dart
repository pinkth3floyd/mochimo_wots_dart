import 'dart:typed_data';
import 'package:mochimo_wots/core/utils/ByteUtils.dart';
import 'package:mochimo_wots/core/protocol/Wots.dart';
import 'package:mochimo_wots/core/hasher/MochimoHasher.dart';
import 'package:mochimo_wots/core/protocol/WotsAddress.dart';
import 'package:mochimo_wots/core/utils/TagUtils.dart';

class WOTSWallet {
  final String? name;
  final Uint8List? wots;
  String? wotsAddrHex;
  final Uint8List? addrTag;
  String? addrTagHex;
  final Uint8List? secret;
  WotsAddress? mochimoAddr;

  WOTSWallet({
    this.name,
    this.wots,
    this.addrTag,
    this.secret,
  }) {
    if (secret != null && secret!.length != 32) {
      throw ArgumentError('Invalid secret length');
    }
    if (addrTag != null && addrTag!.length != 20) {
      throw ArgumentError('Invalid address tag');
    }

    // Create copies of the arrays
    wotsAddrHex = wots != null ? ByteUtils.bytesToHex(wots!) : null;
    addrTagHex = addrTag != null ? ByteUtils.bytesToHex(addrTag!) : null;
    mochimoAddr = (wots != null)
        ? WotsAddress.wotsAddressFromBytes(wots!.sublist(0, WOTS.WOTSSIGBYTES))
        : null;
    if (mochimoAddr != null && addrTag != null) {
      mochimoAddr!.setTag(addrTag!);
    }
  }

  String? getName() => name;

  Uint8List? getWots() => wots != null ? Uint8List.fromList(wots!) : null;

  String? getWotsHex() => wotsAddrHex;

  Uint8List? getWotsPk() =>
      wots != null ? Uint8List.fromList(wots!.sublist(0, WOTS.WOTSSIGBYTES)) : null;

  Uint8List? getWotsPubSeed() =>
      wots?.sublist(WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32);

  Uint8List? getWotsAdrs() =>
      wots?.sublist(WOTS.WOTSSIGBYTES + 32, WOTS.WOTSSIGBYTES + 64);

  Uint8List? getWotsTag() =>
      wots?.sublist(WOTS.WOTSSIGBYTES + 64 - 12, WOTS.WOTSSIGBYTES + 64);

  Uint8List? getAddress() =>
      mochimoAddr != null ? Uint8List.fromList(mochimoAddr!.bytes().sublist(0, 40)) : null;

  Uint8List? getAddrTag() => addrTag != null ? Uint8List.fromList(addrTag!) : null;

  String? getAddrTagHex() => addrTagHex;

  String? getAddrTagBase58() =>
      addrTag != null ? TagUtils.addrTagToBase58(getAddrTag()!) : null;

  Uint8List? getAddrHash() => mochimoAddr?.getAddrHash();

  Uint8List? getSecret() => secret != null ? Uint8List.fromList(secret!) : null;

  bool hasSecret() => secret != null;

  Uint8List sign(Uint8List data) {
    final sourceSeed = secret;
    final sourceWots = wots;
    if (sourceSeed == null || sourceWots == null) {
      throw StateError('Cannot sign without secret key or address');
    }
    if (sourceSeed.length != 32) {
      throw StateError('Invalid sourceSeed length, expected 32, got ${sourceSeed.length}');
    }
    if (sourceWots.length != 2208) {
      throw StateError('Invalid sourceWots length, expected 2208, got ${sourceWots.length}');
    }
    final pk = sourceWots.sublist(0, WOTS.WOTSSIGBYTES);
    final pubSeed = sourceWots.sublist(WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32);
    final rnd2 = sourceWots.sublist(WOTS.WOTSSIGBYTES + 32, WOTS.WOTSSIGBYTES + 64);
    final sig = Uint8List(WOTS.WOTSSIGBYTES);
    WOTS.wotsSign(sig, data, sourceSeed, pubSeed, 0, rnd2);
    return sig;
  }

  bool verify(Uint8List message, Uint8List signature) {
    if (wots == null) {
      throw StateError('Cannot verify without public key (address)');
    }
    final srcAddr = wots!;
    final pk = srcAddr.sublist(0, WOTS.WOTSSIGBYTES);
    final pubSeed = srcAddr.sublist(WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32);
    final rnd2 = srcAddr.sublist(WOTS.WOTSSIGBYTES + 32, WOTS.WOTSSIGBYTES + 64);

    final computedPublicKey = WOTS.wotsPkFromSig(signature, message, pubSeed, rnd2);
    return ByteUtils.areEqual(computedPublicKey, pk);
  }

  static Map<String, Uint8List> componentsGenerator(Uint8List wotsSeed) {
    // Concatenate wotsSeed bytes with ASCII bytes of "seed", "publ", "addr"
    final privateSeedInput = Uint8List(wotsSeed.length + 4);
    privateSeedInput.setRange(0, wotsSeed.length, wotsSeed);
    privateSeedInput.setRange(wotsSeed.length, wotsSeed.length + 4, 'seed'.codeUnits);

    final publicSeedInput = Uint8List(wotsSeed.length + 4);
    publicSeedInput.setRange(0, wotsSeed.length, wotsSeed);
    publicSeedInput.setRange(wotsSeed.length, wotsSeed.length + 4, 'publ'.codeUnits);

    final addrSeedInput = Uint8List(wotsSeed.length + 4);
    addrSeedInput.setRange(0, wotsSeed.length, wotsSeed);
    addrSeedInput.setRange(wotsSeed.length, wotsSeed.length + 4, 'addr'.codeUnits);

    final privateSeed = MochimoHasher.hash(privateSeedInput);
    final publicSeed = MochimoHasher.hash(publicSeedInput);
    final addrSeed = MochimoHasher.hash(addrSeedInput);

    return {
      'private_seed': privateSeed,
      'public_seed': publicSeed,
      'addr_seed': addrSeed,
    };
  }

  void clear() {
    if (secret != null) ByteUtils.clear(secret!);
    if (wots != null) ByteUtils.clear(wots!);
    if (addrTag != null) ByteUtils.clear(addrTag!);
    addrTagHex = null;
    wotsAddrHex = null;
    mochimoAddr = null;
  }

  @override
  String toString() {
    if (wotsAddrHex != null) {
      return '${wotsAddrHex!.substring(0, 32)}...${wotsAddrHex!.substring(wotsAddrHex!.length - 24)}';
    } else if (addrTagHex != null) {
      return 'tag-$addrTagHex';
    }
    return 'Empty address';
  }

    // static WOTSWallet create(String name, Uint8List secret, [Uint8List? v3tag, void Function(Uint8List)? randomGenerator]) {
    //   if (secret.length != 32) {
    //     throw ArgumentError('Invalid secret length');
    //   }

    //   void deterministicRandomGenerator(Uint8List bytes) {
    //     for (int i = 0; i < bytes.length; i++) {
    //       bytes[i] = 0x42;
    //     }
    //   }

    //   Uint8List privateSeed = secret;
    //   Uint8List? sourcePK;
    //   final defaultTag = Uint8List.fromList([0x42, 0x00, 0x00, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00]);
    //   if (randomGenerator != null) {
    //     sourcePK = WOTS.generateRandomAddress(defaultTag, secret, randomGenerator);
    //   } else {
    //     final components = componentsGenerator(secret);
    //     privateSeed = components['private_seed']!;
    //     sourcePK = WOTS.generateAddress(defaultTag, privateSeed, componentsGenerator, deterministicRandomGenerator);
    //   }
    //   if (sourcePK.length != 2208) {
    //     throw StateError('Invalid sourcePK length');
    //   }
    //   Uint8List addrTag = v3tag ?? WotsAddress.wotsAddressFromBytes(sourcePK.sublist(0, 2144)).getTag();
    //   if (addrTag.length != 20) {
    //     throw StateError('Invalid tag');
    //   }
    //   return WOTSWallet(name: name, wots: sourcePK, addrTag: addrTag, secret: privateSeed);
    // }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'wots': wots,
      'addrTag': addrTag,
      'secret': secret,
      'addrTagHex': addrTagHex,
      'wotsAddrHex': wotsAddrHex,
    };
  }
}
