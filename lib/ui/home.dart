import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:govm/generated/i18n.dart';
import 'package:govm/util/util.dart' as util;
import 'package:govm/wallet/aes.dart';
import 'package:govm/wallet/wallet.dart';
import 'package:hex/hex.dart';
import 'change_wallet.dart';
import 'diag.dart';
import 'qrcode.dart';

var _balances = {1: 0};
var _locks = {1: 0};
var _password = '';
String _totalBalance = '0 tc';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() {
    // print("createState");
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  Future<T> showPasswordW<T>(BuildContext context, Uint8List aesPrivKey) {
    TextEditingController _textFieldController = TextEditingController();
    return showDialog(
        context: context,
        // barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(I18n.of(context).password),
            content: TextField(
              controller: _textFieldController,
              obscureText: true,
              decoration: InputDecoration(hintText: "Password of wallet"),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  if (_textFieldController.text == '') {
                    return;
                  }
                  _password = _textFieldController.text;
                  if (aesPrivKey != null) {
                    try {
                      var privKey = decrypt(_password, aesPrivKey);
                      wallet.formKey(HEX.encode(privKey));
                    } catch (err) {
                      myDiag(context, I18n.of(context).ePassword);
                      return;
                    }
                  }
                  Navigator.of(context).pop();
                },
                child: Text(I18n.of(context).ok),
              )
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    if (_password != ''){
      return;
    }
    wallet.load().then((Uint8List aesData) {
      showPasswordW(context, aesData).then((bool) {
        if (aesData == null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewWalletNavigation(_password)),
          );
        }
      });
    });
    wallet.setCallback((bool ok) {
      try {
        setState(() {});
        _getAccount();
      } catch (err) {}
    });
  }

  String _valWithUnit(num input) {
    if (input == null) {
      return '0' + util.unit;
    }
    var value;
    switch (util.unit) {
      case 'tc':
        value = input / 1000000000000;
        break;
      case 't9':
        value = input / 1000000000;
        break;
      case 't6':
        value = input / 1000000;
        break;
      case 't3':
        value = input / 1000;
        break;
      default:
        value = input;
    }
    return value.toStringAsFixed(3) + util.unit;
  }

  void _showBalance() {
    var total = 0;
    for (var i in util.allChains) {
      total += _balances[i];
      total += _locks[i];
    }
    _totalBalance = _valWithUnit(total);
    setState(() {});
  }

  void _getAccount() {
    for (var i in util.allChains) {
      util.getAccount(i, wallet.address).then((num val) {
        if (_balances[i] == val) {
          return;
        }
        _balances[i] = val;
        _showBalance();
      });
      util.getAccountLocked(i, wallet.address).then((num val) {
        if (_locks[i] == val) {
          return;
        }
        _locks[i] = val;
        _showBalance();
      });
    }
  }

  Widget _chainInfo(num chain, num balance, num locked) {
    Color bg = Colors.cyan[100];
    if (chain % 2 == 0) {
      bg = Colors.cyan[50];
    }
    if (locked == null || locked <= 0) {
      return new Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.yellow, width: 1)),
        child: new Row(
          children: [
            SizedBox(width: 10),
            new Container(
              padding: const EdgeInsets.only(right: 8.0),
              child: new Text(
                I18n.of(context).chainBalance('$chain'),
                style: new TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 10),
            new Text(_valWithUnit(balance),
                style: new TextStyle(
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      );
    }
    var balanceW = new Expanded(
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          new Container(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: new Text(
              I18n.of(context).chainBalance('$chain'),
              style: new TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          new Text(_valWithUnit(balance)),
        ],
      ),
    );
    Widget lockW = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        new Container(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: new Text(
            I18n.of(context).freeze,
            style: new TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        new Text(_valWithUnit(locked)),
      ],
    );
    return new Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.yellow, width: 1)),
      padding: const EdgeInsets.all(20.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          balanceW,
          lockW,
        ],
      ),
    );
  }

  String _shortString(String input, {int length = 6}) {
    if (input == null) {
      return '';
    }
    if (input.length < length) {
      return input;
    }
    return input.substring(0, length) + '...';
  }

  @override
  Widget build(BuildContext context) {
    // _getAccount();
    Widget titleSection = new Container(
      decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.yellow, width: 1)),
      padding: const EdgeInsets.all(32.0),
      child: new Row(
        children: [
          new Expanded(
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                new Container(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: new Text(
                    I18n.of(context).totalAssets,
                    style: new TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                new Text(_totalBalance),
              ],
            ),
          ),
          Column(children: [
            IconButton(
              onPressed: () {
                showQRCode(context, wallet.address,
                    title: I18n.of(context).walletAddress);
              },
              icon: Image.asset(
                'images/qrcode.jpg',
                height: 40.0,
                fit: BoxFit.cover,
              ),
            ),
            new Text(_shortString(wallet.address, length: 8)),
          ]),
        ],
      ),
    );

    return Scaffold(
      appBar: new AppBar(
        title: new Text(I18n.of(context).home),
        actions: <Widget>[
          new IconButton(
            // action button
            icon: new Icon(Icons.add_circle),
            onPressed: () {
              print("AppBar.action");
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NewWalletNavigation(_password)),
              );
            },
          ),
        ],
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
            child: Center(
                child: Column(
          children: <Widget>[
            titleSection,
            Text(''),
            Column(
                children: util.allChains.map((num i) {
              return _chainInfo(i, _balances[i], _locks[i]);
              // return _chainInfo(i, _balances[i], 100);
            }).toList()),
          ],
        ))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getAccount,
        tooltip: I18n.of(context).refresh,
        child: Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
