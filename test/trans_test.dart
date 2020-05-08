import 'dart:convert';
import 'dart:typed_data';
import 'package:hex/hex.dart';
import 'package:govm/wallet/aes.dart';

// BigEndian
BigInt bytes2BigInt(Uint8List bytes) {
  BigInt result = new BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    result = result << 8;
    result += new BigInt.from(bytes[i]);
  }
  return result;
}

// BigEndian
Uint8List bigInt2Bytes(BigInt number, {int len = 0}) {
  // Not handling negative numbers. Decide how you want to do that.
  int offset = 0;
  int bytes = (number.bitLength + 7) >> 3;
  if (len > bytes) {
    offset = len - bytes;
    bytes = len;
  }

  var b256 = new BigInt.from(256);
  var result = new Uint8List(bytes);
  for (int i = bytes - 1; i >= offset; i--) {
    result[i] = number.remainder(b256).toInt();
    number = number >> 8;
  }
  return result;
}

void main() {
  var val = 123456789012345;
  // var enc = intToBytes(val,8);
  BigInt big = BigInt.from(val);
  print(big.toString());
  // 1234567890

  var enc = bigInt2Bytes(big, len: 8);
  print(HEX.encode(enc));

  var nBig = bytes2BigInt(enc);
  print(nBig.toString());
  print(nBig.bitLength);
  // 00000000499602d2
  // 00000000499602d2

  var key = '12345';
  var msg = Uint8List.fromList('elements'.codeUnits);
  var aesEnc = encrypt(key,msg);
  var aesDec = decrypt(key,aesEnc);
  print(HEX.encode(aesEnc));
  print(HEX.encode(aesDec));
  print(utf8.decode(aesDec));
}
