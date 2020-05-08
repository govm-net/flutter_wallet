
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha3.dart';
import 'package:pointycastle/pointycastle.dart';

Uint8List hash(Uint8List message) {
  var hash = new SHA3Digest(256, false);
  return hash.process(message);
}

const _aesHead = 'govm';
Uint8List encrypt(String keyStr, Uint8List msg) {
  final key = hash(Uint8List.fromList(keyStr.codeUnits));
  CipherParameters params =
      new PaddedBlockCipherParameters(new KeyParameter(key), null);
  BlockCipher encryptionCipher = new PaddedBlockCipher("AES/ECB/PKCS7");
  encryptionCipher.init(true, params);
  var data = _aesHead.codeUnits+msg;
  Uint8List encrypted = encryptionCipher.process(Uint8List.fromList(data));
  return encrypted;
}

///AES解密
Uint8List decrypt(String keyStr, Uint8List data) {
  final key = hash(Uint8List.fromList(keyStr.codeUnits));
  CipherParameters params =
      new PaddedBlockCipherParameters(new KeyParameter(key), null);
  BlockCipher decryptionCipher = new PaddedBlockCipher("AES/ECB/PKCS7");
  decryptionCipher.init(false, params);
  var plaintext = decryptionCipher.process(data);
  var head = plaintext.sublist(0,_aesHead.length);
  assert(utf8.decode(head)==_aesHead);
  return plaintext.sublist(_aesHead.length);
}
