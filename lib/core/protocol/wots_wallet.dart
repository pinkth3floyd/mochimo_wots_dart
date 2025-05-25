import 'dart:typed_data';
import 'package:mochimo_wots/core/utils/byte_utils.dart';
import 'package:mochimo_wots/core/protocol/wots.dart';
import 'package:mochimo_wots/core/hasher/mochimo_hasher.dart';
import 'package:mochimo_wots/core/protocol/wots_address.dart';
import 'package:mochimo_wots/core/utils/tag_utils.dart';

class WOTSWallet {
  String? name;
  Uint8List? _wots;
  String? wotsAddrHex;
  Uint8List? _addrTag;
  String? addrTagHex;
  Uint8List? _secret;
  WotsAddress? mochimoAddr;

  WOTSWallet({
    this.name,
    Uint8List? wots,
    Uint8List? addrTag,
    Uint8List? secret,
  }) {
    if (secret != null && secret.length != 32) {
      throw ArgumentError('Invalid secret length');
    }
    if (addrTag != null && addrTag.length != WotsAddress.ADDR_TAG_LEN) {
      throw ArgumentError('Invalid address tag');
    }

    // Store copies of the arrays
    _wots = wots != null ? Uint8List.fromList(wots) : null;
    _addrTag = addrTag != null ? Uint8List.fromList(addrTag) : null;
    _secret = secret != null ? Uint8List.fromList(secret) : null;

    // Create hex strings
    wotsAddrHex = _wots != null ? ByteUtils.bytesToHex(_wots!) : null;
    addrTagHex = _addrTag != null ? ByteUtils.bytesToHex(_addrTag!) : null;
    mochimoAddr = (_wots != null)
        ? WotsAddress.wotsAddressFromBytes(_wots!.sublist(0, WOTS.WOTSSIGBYTES))
        : null;
    if (mochimoAddr != null && _addrTag != null) {
      mochimoAddr!.setTag(_addrTag!);
    }
  }

  String? getName() => name;

  Uint8List? getWots() => _wots == null ? null : Uint8List.fromList(_wots!);

  String? getWotsHex() => wotsAddrHex;

  Uint8List? getWotsPk() => _wots?.sublist(0, WOTS.WOTSSIGBYTES);

  Uint8List? getWotsPubSeed() =>
      _wots?.sublist(WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32);

  Uint8List? getWotsAdrs() =>
      _wots?.sublist(WOTS.WOTSSIGBYTES + 32, WOTS.WOTSSIGBYTES + 64);

  Uint8List? getWotsTag() => _wots?.sublist(
      WOTS.WOTSSIGBYTES + 64 - WotsAddress.ADDR_TAG_LEN,
      WOTS.WOTSSIGBYTES + 64);

  Uint8List? getAddress() => mochimoAddr?.bytes().sublist(0, 40);

  Uint8List? getAddrTag() =>
      _addrTag == null ? null : Uint8List.fromList(_addrTag!);

  String? getAddrTagHex() => addrTagHex;

  String? getAddrTagBase58() =>
      _addrTag == null ? null : TagUtils.addrTagToBase58(_addrTag!);

  Uint8List? getAddrHash() => mochimoAddr?.getAddrHash();

  Uint8List? getSecret() =>
      _secret == null ? null : Uint8List.fromList(_secret!);

  bool hasSecret() => _secret != null;

  Uint8List sign(Uint8List data) {
    if (_secret == null || _wots == null) {
      throw StateError('Cannot sign without secret key or address');
    }
    if (_secret!.length != 32) {
      throw StateError(
          'Invalid sourceSeed length, expected 32, got ${_secret!.length}');
    }
    if (_wots!.length != 2208) {
      throw StateError(
          'Invalid sourceWots length, expected 2208, got ${_wots!.length}');
    }
    final pubSeed = _wots!.sublist(WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32);
    final rnd2 = _wots!.sublist(WOTS.WOTSSIGBYTES + 32, WOTS.WOTSSIGBYTES + 64);
    final sig = Uint8List(WOTS.WOTSSIGBYTES);
    WOTS.wotsSign(sig, data, _secret!, pubSeed, 0, rnd2);
    return sig;
  }

  bool verify(Uint8List message, Uint8List signature) {
    if (_wots == null) {
      throw StateError('Cannot verify without public key (address)');
    }
    final pk = _wots!.sublist(0, WOTS.WOTSSIGBYTES);
    final pubSeed = _wots!.sublist(WOTS.WOTSSIGBYTES, WOTS.WOTSSIGBYTES + 32);
    final rnd2 = _wots!.sublist(WOTS.WOTSSIGBYTES + 32, WOTS.WOTSSIGBYTES + 64);

    final computedPublicKey =
        WOTS.wotsPkFromSig(signature, message, pubSeed, rnd2);
    return ByteUtils.areEqual(computedPublicKey, pk);
  }

  void clear() {
    if (_secret case final s?) {
      ByteUtils.clear(s);
      _secret = null;
    }
    if (_wots case final w?) {
      ByteUtils.clear(w);
      _wots = null;
    }
    if (_addrTag case final t?) {
      ByteUtils.clear(t);
      _addrTag = null;
    }
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

  static WOTSWallet create(String name, Uint8List secret,
      [Uint8List? v3tag, void Function(Uint8List)? randomGenerator]) {
    if (secret.length != 32) {
      throw ArgumentError('Invalid secret length');
    }

    Uint8List privateSeed = secret;
    Uint8List? sourcePK;
    final defaultTag = Uint8List(12)..fillRange(0, 12, 0x42); // Use 12-byte tag
    if (randomGenerator != null) {
      sourcePK =
          WOTS.generateRandomAddress(defaultTag, secret, randomGenerator);
    } else {
      final components = componentsGenerator(secret);
      privateSeed = components['private_seed']!;
      sourcePK =
          WOTS.generateAddress(defaultTag, privateSeed, componentsGenerator);
    }
    if (sourcePK.length != 2208) {
      throw StateError('Invalid sourcePK length');
    }
    Uint8List addrTag = v3tag ??
        WotsAddress.wotsAddressFromBytes(sourcePK.sublist(0, 2144)).getTag();
    if (addrTag.length != WotsAddress.ADDR_TAG_LEN) {
      throw StateError('Invalid tag');
    }
    return WOTSWallet(
        name: name, wots: sourcePK, addrTag: addrTag, secret: privateSeed);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'wots': _wots,
      'addrTag': _addrTag,
      'secret': _secret,
      'addrTagHex': addrTagHex,
      'wotsAddrHex': wotsAddrHex,
    };
  }

  static Map<String, Uint8List> componentsGenerator(Uint8List wotsSeed) {
    // Concatenate wotsSeed bytes with ASCII bytes of "seed", "publ", "addr"
    final privateSeedInput = Uint8List(wotsSeed.length + 4);
    privateSeedInput.setRange(0, wotsSeed.length, wotsSeed);
    privateSeedInput.setRange(
        wotsSeed.length, wotsSeed.length + 4, 'seed'.codeUnits);

    final publicSeedInput = Uint8List(wotsSeed.length + 4);
    publicSeedInput.setRange(0, wotsSeed.length, wotsSeed);
    publicSeedInput.setRange(
        wotsSeed.length, wotsSeed.length + 4, 'publ'.codeUnits);

    final addrSeedInput = Uint8List(wotsSeed.length + 4);
    addrSeedInput.setRange(0, wotsSeed.length, wotsSeed);
    addrSeedInput.setRange(
        wotsSeed.length, wotsSeed.length + 4, 'addr'.codeUnits);

    final privateSeed = MochimoHasher.hash(privateSeedInput);
    final publicSeed = MochimoHasher.hash(publicSeedInput);
    final addrSeed = MochimoHasher.hash(addrSeedInput);

    return {
      'private_seed': privateSeed,
      'public_seed': publicSeed,
      'addr_seed': addrSeed,
    };
  }
}
