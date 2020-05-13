import 'dart:typed_data';
import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'package:hex/hex.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:pointycastle/digests/sha3.dart';
import "package:pointycastle/ecc/curves/secp256k1.dart";
import 'package:pointycastle/ecc/api.dart';
import 'package:path_provider/path_provider.dart';

import 'aes.dart';

typedef Callback = void Function(bool ok);

Wallet wallet = new Wallet();

class Wallet {
  ECPair _privECC;
  String address = '';
  Uint8List privKey;
  final secp256k1 = new ECCurve_secp256k1();
  List<Callback> cbList = [];

  formSeed(String seed) {
    if (seed == "") {
      return;
    }
    var hs = Uint8List.fromList(seed.codeUnits);
    privKey = doGovmHash(hs);
    _privECC = ECPair.fromPrivateKey(privKey, compressed: true);
    address = getAddressByPublicKey(_privECC.publicKey);
    for (var cb in cbList) {
      cb(true);
    }
  }

  formKey(String hexKey) {
    if (hexKey == "") {
      return;
    }
    privKey = HEX.decode(hexKey);
    _privECC = ECPair.fromPrivateKey(privKey, compressed: true);
    address = getAddressByPublicKey(_privECC.publicKey);
    for (var cb in cbList) {
      cb(true);
    }
  }

  random() {
    _privECC = ECPair.makeRandom(compressed: true);
    privKey = _privECC.privateKey;
    address = getAddressByPublicKey(_privECC.publicKey);

    for (var cb in cbList) {
      cb(true);
    }
  }

  Future<Uint8List> load() async {
    try {
      File file = await _getLocalFile();
      var hexKey = await file.readAsString();
      if (hexKey != "") {
        // formKey(hexKey);
        return HEX.decode(hexKey);
      }
    } catch (err) {}
    for (var cb in cbList) {
      cb(false);
    }
    return null;
  }

  save(String key) {
    try {
      _getLocalFile().then((File f) {
        var enc = encrypt(key, privKey);
        f.writeAsString(HEX.encode(enc));
      });
    } catch (err) {
      print("fail to save wallet");
    }
  }

  reset(){
    this.privKey = null;
    this.address = '';
    try {
      _getLocalFile().then((File f) {
        f.delete();
      });
    } catch (err) {
      print("fail to save wallet");
    }
  }

  setCallback(Callback cb) {
    this.cbList.add(cb);
    // if(address != ""){
    //   cb(true);
    // }
  }

  Uint8List doSign(Uint8List message) {
    var msgHash = doGovmHash(message);
    var sign = _privECC.sign(msgHash);
    var index = _calcPubKeyRecoveryParam(msgHash, sign, _privECC.publicKey);
    index += 4; // compressed
    index += 27; // compact
    var result = new Uint8List(sign.length + 1);
    result[0] = index;
    for (int i = 0; i < sign.length; i++) {
      result[i + 1] = sign[i].toInt();
    }

    return result;
  }

  // return public key
  Uint8List doRecover(Uint8List message, Uint8List sign) {
    var msgHash = doGovmHash(message);
    var index = sign[0] - 31;

    BigInt r = _decodeBigInt(sign.sublist(1, 33));
    BigInt s = _decodeBigInt(sign.sublist(33, 65));
    var ecSig = new ECSignature(r, s);
    var e = _decodeBigInt(msgHash);
    ECPoint pub = _recoverPubKey(e, ecSig, index);
    return pub.getEncoded();
  }

  static Uint8List doGovmHash(Uint8List message) {
    var hash = new SHA3Digest(256, false);
    var prefix = new Uint8List.fromList("govm".codeUnits);
    hash.update(prefix, 0, prefix.length);
    return hash.process(message);
  }

  static String getAddressByPublicKey(Uint8List key) {
    var nk = new Uint8List(key.length + 1);
    for (int i = 0; i < key.length; i++) {
      nk[i] = key[i].toInt();
    }
    nk[key.length] = 1;

    var hash = doGovmHash(nk);
    var addr = hash.sublist(0, 24);
    addr[0] = 1;
    return HEX.encode(addr);
  }

  int _calcPubKeyRecoveryParam(Uint8List msg, Uint8List sign, Uint8List q) {
    BigInt r = _decodeBigInt(sign.sublist(0, 32));
    BigInt s = _decodeBigInt(sign.sublist(32, 64));
    var ecSig = new ECSignature(r, s);
    var e = _decodeBigInt(msg);
    ECPoint Q = secp256k1.curve.decodePoint(q);
    var publicKey = new ECPublicKey(Q, secp256k1);
    for (int i = 0; i < 4; i++) {
      // ECPoint Qprime = recoverPubKey(e, ecSig, i);
      ECPoint pub = _recoverPubKey(e, ecSig, i);
      if (pub == publicKey.Q) {
        return i;
      }
    }
    throw 'Unable to find valid recovery factor';
  }

  BigInt _decodeBigInt(List<int> bytes) {
    BigInt result = new BigInt.from(0);
    for (int i = 0; i < bytes.length; i++) {
      result += new BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }
    return result;
  }

  ECPoint _recoverPubKey(BigInt e, ECSignature ecSig, int i) {
    BigInt n = secp256k1.n;
    ECPoint G = secp256k1.G;

    BigInt r = ecSig.r;
    BigInt s = ecSig.s;

    // A set LSB signifies that the y-coordinate is odd
    int isYOdd = i & 1;

    // The more significant bit specifies whether we should use the
    // first or second candidate key.
    int isSecondKey = i >> 1;

    // 1.1 Let x = r + jn
    BigInt x = isSecondKey > 0 ? r + n : r;
    ECPoint R = secp256k1.curve.decompressPoint(isYOdd, x);
    ECPoint nR = R * n;
    if (!nR.isInfinity) {
      throw 'nR is not a valid curve point';
    }

    BigInt eNeg = (-e) % n;
    BigInt rInv = r.modInverse(n);

    ECPoint Q = _multiplyTwo(R, s, G, eNeg) * rInv;
    return Q;
  }

  ECPoint _multiplyTwo(ECPoint t, BigInt j, ECPoint x, BigInt k) {
    int i = max(j.bitLength, k.bitLength) - 1;
    ECPoint R = t.curve.infinity;
    ECPoint both = t + x;

    while (i >= 0) {
      bool jBit = _testBit(j, i);
      bool kBit = _testBit(k, i);

      R = R.twice();

      if (jBit) {
        if (kBit) {
          R = R + both;
        } else {
          R = R + t;
        }
      } else if (kBit) {
        R = R + x;
      }

      --i;
    }

    return R;
  }

  bool _testBit(BigInt j, int n) {
    return (j >> n).toUnsigned(1).toInt() == 1;
  }

  Future<File> _getLocalFile() async {
    // get the path to the document directory.
    if (Platform.isIOS || Platform.isAndroid) {
      String dir = (await getApplicationDocumentsDirectory()).path;
      return new File('$dir/wallet.dat');
    }
    return File('./wallet.dat');
  }
}
