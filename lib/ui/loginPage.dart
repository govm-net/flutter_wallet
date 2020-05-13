import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:govm/generated/i18n.dart';
import 'package:govm/ui/diag.dart';
import 'package:govm/ui/change_wallet.dart' as wp;
import 'package:govm/wallet/aes.dart';
import 'package:govm/wallet/wallet.dart';
import 'package:hex/hex.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final logo = Hero(
      tag: 'hero',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 60.0,
        child: Image.asset('images/govm.png'),
      ),
    );
    TextEditingController _textFieldController = TextEditingController();
    final password = TextFormField(
      autofocus: false,
      obscureText: true,
      controller: _textFieldController,
      decoration: InputDecoration(
        hintText: I18n.of(context).password,
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
    );

    final loginButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        onPressed: () {
          // Navigator.of(context).pushNamed('home');
          if (_textFieldController.text == '') {
            return;
          }
          wallet.load().then((Uint8List aesPrivKey) {
            wp.password = _textFieldController.text;
            if (aesPrivKey != null) {
              try {
                var privKey = decrypt(wp.password, aesPrivKey);
                wallet.formKey(HEX.encode(privKey));
              } catch (err) {
                myDiag(context, I18n.of(context).ePassword);
                _textFieldController.text = "";
                return;
              }
              Navigator.of(context).pushReplacementNamed('home');
            } else {
              Navigator.of(context).pushNamed('newWallet').then((value) {
                if (value == null || value.toString() == '') {
                  return;
                }
                wallet.formKey(value.toString());
                wallet.save(wp.password);
                _textFieldController.text = "";
                Navigator.of(context).pushReplacementNamed('home');
              });
            }
          });
        },
        padding: EdgeInsets.all(12),
        color: Colors.lightBlueAccent,
        child:
            Text(I18n.of(context).login, style: TextStyle(color: Colors.white)),
      ),
    );

    final resetLabel = FlatButton(
      child: Text(
        I18n.of(context).resetWallet,
        style: TextStyle(color: Colors.black54),
      ),
      onPressed: () {
        print('Reset Wallet');
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(I18n.of(context).resetWallet),
                content: Text(I18n.of(context).resetMsg),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(I18n.of(context).cancel),
                  ),
                  FlatButton(
                    onPressed: () {
                      _textFieldController.text = "";
                      wallet.reset();
                      Navigator.of(context).pop();
                    },
                    child: Text(I18n.of(context).ok),
                  )
                ],
              );
            });
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(left: 24.0, right: 24.0),
          children: <Widget>[
            logo,
            SizedBox(height: 48.0),
            password,
            SizedBox(height: 24.0),
            loginButton,
            resetLabel
          ],
        ),
      ),
    );
  }
}
