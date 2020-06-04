import 'package:flutter/material.dart';
import 'package:govm/generated/i18n.dart';
import 'package:govm/util/util.dart' as util;
import 'package:govm/wallet/wallet.dart';
import 'change_wallet.dart' as wp;
import 'qrcode.dart';

var _balances = {1: 0};
var _votes = {1: 0};
var _password = '';
String _totalBalance = '0 govm';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    if (_password != '') {
      return;
    }

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
      case 'govm':
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
      if (_balances[i] != null) {
        total += _balances[i];
      }
      if (_votes[i] != null) {
        total += _votes[i];
      }
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
      util.getAccountVotes(i, wallet.address).then((num val) {
        print('$val vote');
        if (_votes[i] == val) {
          return;
        }
        _votes[i] = val;
        _showBalance();
      });
    }
  }

  Widget _chainInfo(num chain, num balance, num votes) {
    Color bg = Colors.cyan[100];
    if (chain % 2 == 0) {
      bg = Colors.cyan[50];
    }
    if (votes == null || votes <= 0) {
      print("error vote,$votes");
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
    votes /= util.voteCost;
    votes = votes.toInt();
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
            I18n.of(context).votes,
            style: new TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        new Text('$votes'),
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
    if (wallet.address != '') {
      _getAccount();
    }
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
              Navigator.of(context).pushNamed('newWallet').then((value) {
                if (value == null || value.toString() == '') {
                  return;
                }
                wallet.formKey(value.toString());
                wallet.save(wp.password);
              });
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
              return _chainInfo(i, _balances[i], _votes[i]);
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
