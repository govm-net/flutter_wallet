import 'dart:typed_data';

import 'package:govm/util/transaction.dart';
import 'package:govm/util/util.dart';
import 'package:govm/wallet/wallet.dart';
import 'package:hex/hex.dart';


main()async {
  Wallet w = new Wallet();
  var key = Wallet.doGovmHash(Uint8List.fromList('123456789'.codeUnits));
  w.formKey(HEX.encode(key));
  Transaction trans = new Transaction(w.address,"1",1000);
  trans.opsMove('2');
  var data = trans.getSignData();
  var sign = w.doSign(data);
  trans.setSign(sign);
  var out = trans.output();
  print('address:'+w.address);
  print('sign:'+HEX.encode(sign));
  print('data:'+HEX.encode(data));
  print('transaction:'+HEX.encode(out));
  var transKey = Wallet.doGovmHash(out);
  await sendTransaction('1', HEX.encode(transKey), out).then((String rst){
    print('send result:$rst');
  });


}
