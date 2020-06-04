import 'package:flutter/material.dart';
import 'package:govm/generated/i18n.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:govm/util/util.dart' as util;

var _version = '';
var _buildNumber = '';
var _govmNet = "http://govm.net";

class SettingPageWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SettingPageWidgetState();
  }
}

class SettingPageWidgetState extends State<SettingPageWidget> {
  @override
  Widget build(BuildContext context) {
    try {
      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        _version = packageInfo.version==""?"0.1.0":packageInfo.version;
        _buildNumber = packageInfo.buildNumber==""?"1":packageInfo.buildNumber;
        setState(() {}); 
      });
    } catch (err) {}

    return new Scaffold(
        appBar: new AppBar(
          title: new Text(I18n.of(context).setting),
        ),
        body: Container(
            decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(17),
                border: Border.all(width: 1)),
            padding: const EdgeInsets.all(20.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image(image: AssetImage('images/logo.png')),
                  Row(children: <Widget>[
                    Text(''),
                  ]),
                  InkWell(
                      child: Text(_govmNet,
                          overflow: TextOverflow.ellipsis,
                          style: new TextStyle(
                              fontSize: 18,
                              decoration: TextDecoration.underline)),
                      onTap: () => launch(_govmNet)),
                  Text(
                      I18n.of(context).version +
                          ': ' +
                          _version +
                          "+" +
                          _buildNumber,
                      style: new TextStyle(
                        fontSize: 18,
                      )),
                  Text(I18n.of(context).apiServer + ': ${util.apiServer}',
                      style: new TextStyle(
                        fontSize: 18,
                      )),
                ])));
  }
}
