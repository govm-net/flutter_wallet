import 'dart:typed_data';

import 'package:hex/hex.dart';
import 'encode.dart';

const _timeOffset = 600000;
const _addressLen = 24;
const defaultEnergy = 1000000;

class Transaction {
  BigInt time; //8bit
  Uint8List user; //24bit
  BigInt chain; //8bit
  BigInt energy; //8bit
  BigInt cost; //8bit
  int ops; //1bit
  Uint8List data; //

  Uint8List sign; //65bit?
  Uint8List key; //32bit

  Transaction(String user, String chain, num cost, {num energy = defaultEnergy}) {
    this.time =
        BigInt.from(DateTime.now().millisecondsSinceEpoch - _timeOffset);
    this.user = HEX.decode(user);
    this.chain = BigInt.parse(chain);
    this.cost = BigInt.from(cost);
    this.energy = BigInt.from(energy);
    this.data = new Uint8List(0);
    assert(this.user.length == _addressLen);
    assert(energy > 1000);
    assert(this.chain > BigInt.zero);
    assert(this.cost >= BigInt.zero);
  }

  Uint8List getSignData() {
    var opsList = Uint8List(1);
    opsList[0]=ops;
    var out = bigInt2Bytes(time, len: 8) +
        user +
        bigInt2Bytes(chain, len: 8) +
        bigInt2Bytes(energy, len: 8) +
        bigInt2Bytes(cost, len: 8) +
        opsList+
        data;
    return Uint8List.fromList(out);
  }

  Uint8List output() {
    var opsList = Uint8List(1);
    var signLenList = Uint8List(1);
    opsList[0]=ops;
    signLenList[0]=this.sign.length;
    var out = signLenList+
        sign+
        bigInt2Bytes(time, len: 8) +
        user +
        bigInt2Bytes(chain, len: 8) +
        bigInt2Bytes(energy, len: 8) +
        bigInt2Bytes(cost, len: 8) +
        opsList+
        data;
    return Uint8List.fromList(out);
  }

  setSign(Uint8List sign) {
    this.sign = sign;
    assert(sign.length > 30);
    // assert(this.data.length > 0);
  }

  opsTransfer(String peer) {
    this.ops = 0;
    data = HEX.decode(peer);
    assert(data.length == _addressLen);
  }

  opsMove(String dstChain) {
    this.ops = 1;
    var big = BigInt.parse(dstChain);
    data = bigInt2Bytes(big, len: 8);
  }

  opsVote(String peer) {
    this.ops = 8;
    data = HEX.decode(peer);
    assert(data.length == _addressLen);
  }

  opsUnvote() {
    this.ops = 9;
  }
}
