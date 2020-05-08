import 'dart:typed_data';

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