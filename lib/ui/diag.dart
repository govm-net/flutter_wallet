
import 'package:flutter/material.dart';
import 'package:govm/generated/i18n.dart';

Future<T> myDiag<T>(BuildContext context, String info,
    {String title = 'Info'}) {
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(info),
          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(I18n.of(context).ok),
            )
          ],
        );
      });
}