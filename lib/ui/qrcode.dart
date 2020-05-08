import 'package:flutter/material.dart';
import 'package:govm/generated/i18n.dart';
import 'package:qr_flutter/qr_flutter.dart';
// import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:flutter_clipboard_manager/flutter_clipboard_manager.dart';

String _qrTitle = '';
String _qrData = '';

showQRCode(BuildContext context, String data, {String title = 'QR Code'}) {
  _qrData = data;
  _qrTitle = title;
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => _QrCodeWidget()),
  );
}

class _QrCodeWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _QrCodeWidgetState();
  }
}

class _QrCodeWidgetState extends State<_QrCodeWidget> {
  @override
  Widget build(BuildContext context) {
    String text1 = '';
    String text2 = '';
    if (_qrData.length < 24) {
      text1 = _qrData;
    } else {
      text1 = _qrData.substring(0, 24);
      text2 = _qrData.substring(24);
    }
    var center = new Center(
      child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        QrImage(
          data: "govm:" + _qrData,
          version: QrVersions.auto,
          size: 200.0,
        ),
        Text(
          I18n.of(context).account,
        ),
        Text(
          text1,
        ),
        Text(
          text2,
        ),
        RaisedButton(
          onPressed: () {
            FlutterClipboardManager.copyToClipBoard(_qrData).then((result) {
              if (result) {
                print("copy address");
              }
            });
          },
          child: Text(I18n.of(context).copyAddr),
        ),
      ]),
    );
    var qrWidget = new Scaffold(
      appBar: new AppBar(
        title: new Text(_qrTitle),
      ),
      body: new Center(
          child: Scrollbar(child: SingleChildScrollView(child: center))),
    );
    return qrWidget;
  }
}
