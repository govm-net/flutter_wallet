import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:flutter/material.dart';
import 'package:govm/generated/i18n.dart';
import 'package:govm/wallet/wallet.dart';
import 'package:hex/hex.dart';
import 'package:bip39/bip39.dart' as bip39;

import 'diag.dart';

class NewWalletNavigation extends StatelessWidget {
  final String password;
  NewWalletNavigation(this.password,{ Key key }):super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController _textEditingCtl1 = new TextEditingController();
    TextEditingController _textEditingCtl2 = new TextEditingController();
    _textEditingCtl1.text =
        HEX.encode(ECPair.makeRandom(compressed: true).privateKey);
    _textEditingCtl2.text = bip39.generateMnemonic();
    var private = Scaffold(
      body: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                helperText: I18n.of(context).wDesc1,
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              controller: _textEditingCtl1,
              maxLines: 4,
            ),
            RaisedButton(
              child: Text(I18n.of(context).change),
              onPressed: () {
                var privECC = ECPair.makeRandom(compressed: true);
                _textEditingCtl1.text = HEX.encode(privECC.privateKey);
              },
            ),
          ]),
      floatingActionButton: FloatingActionButton(
        tooltip: 'OK',
        child: Icon(Icons.check),
        onPressed: () {
          var privKey = _textEditingCtl1.text;
          try {
            var pk = HEX.decode(privKey);
            assert(pk.length == 32);
          } catch (err) {
            myDiag(context, I18n.of(context).wDesc2);
            return;
          }
          try {
            wallet.formKey(privKey);
            wallet.save(password);
          } catch (err) {
            myDiag(context, I18n.of(context).wDesc2);
            return;
          }
          myDiag(context, I18n.of(context).wSeccess).then((bool) {
            Navigator.pop(context);
          });
          print('success to change wallet');
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
    var seed = Scaffold(
      body: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                helperText: I18n.of(context).wDesc3,
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              maxLines: 5,
              controller: _textEditingCtl2,
              // onSubmitted: (String v) {
              //   print("TextField submit");
              // },
            ),
            RaisedButton(
              child: Text(I18n.of(context).change),
              onPressed: () {
                _textEditingCtl2.text = bip39.generateMnemonic();
              },
            ),
          ]),
      floatingActionButton: FloatingActionButton(
        tooltip: 'OK',
        child: Icon(Icons.check),
        onPressed: () {
          var seedKey = _textEditingCtl2.text;
          try {
            assert(seedKey.length > 15);
            wallet.formSeed(seedKey);
            wallet.save(password);
          } catch (err) {
            myDiag(context, I18n.of(context).wDesc4);
            return;
          }
          myDiag(context, I18n.of(context).wSeccess).then((bool) {
            Navigator.pop(context);
          });
          // print('success to change wallet');
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(I18n.of(context).loadWallet),
          bottom: TabBar(
            // indicatorWeight: 3.0,
            tabs: <Widget>[
              Tab(text: I18n.of(context).privateKey),
              Tab(text: I18n.of(context).mnemonic),
              Tab(text: I18n.of(context).description),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            private,
            seed,
            Column(children: <Widget>[
              Text(
                I18n.of(context).walletWarning1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                I18n.of(context).walletWarning3,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                I18n.of(context).walletWarning2,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                I18n.of(context).walletWarning4,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],),
          ],
        ),
      ),
    );
  }
}
