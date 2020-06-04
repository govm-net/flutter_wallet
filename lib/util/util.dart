import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'encode.dart';

const core = 'ff0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

// String apiServer = kIsWeb ? '' : 'http://govm.net';
String apiServer = kIsWeb ? '' : 'http://govm.top:9090';
String unit = 'govm';
num apiVersion = 1;
var allChains = [1, 2];
Map<String, _UpdateItem> accounts = {};
Map<String, _UpdateItem> votes = {};
const _updateLimit = 10000;
const voteCost = 1000000000;

class _UpdateItem {
  int lastTime;
  num balance;
  _UpdateItem(this.lastTime, this.balance);
}

num getBaseOfUnit({String u = 'govm'}) {
  switch (u) {
    case 'tc':
      return 1000000000000;
      break;
    case 't9':
    case 'govm':
      return 1000000000;
      break;
    case 't6':
      return 1000000;
      break;
    case 't3':
      return 1000;
      break;
    case 't0':
      return 1;
      break;
    default:
      print('unknow unit:$u');
      return 1;
  }
}

Future<num> getAccount(num chain, String address) async {
  var now = DateTime.now().millisecondsSinceEpoch;
  var have = accounts['$chain.$address'];
  if (have != null) {
    if (have.lastTime + _updateLimit > now) {
      print('hit cache(account)');
      return have.balance;
    }
  }
  var url = '$apiServer/api/v$apiVersion/$chain/account?address=$address';
  var httpClient = new HttpClient();

  num result = 0;
  try {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    if (response.statusCode == HttpStatus.ok) {
      var json = await response.transform(utf8.decoder).join();
      var data = jsonDecode(json);
      result = data['cost'];
      accounts['$chain.$address'] =
          _UpdateItem(DateTime.now().millisecondsSinceEpoch, result);
      print('get account:$chain,$address,$result');
    } else {
      print('Error getAccount:\nHttp status ${response.statusCode}');
    }
  } catch (exception) {
    print('Failed getAccount,$url');
  }

  return result;
}

Future<num> getAccountVotes(num chain, String address) async {
  var now = DateTime.now().millisecondsSinceEpoch;
  var have = votes['$chain.$address'];
  if (have != null) {
    if (have.lastTime + _updateLimit > now) {
      print('hit cache(locked)');
      return have.balance;
    }
  }
  
  return getDBData(chain, "dbVote", address).then((List<int> value) {
    if (value.length < 32){
      return 0;
    }
    var v = bytes2BigInt(value.sublist(24, 32));
    return v.toInt();
  }); 
}

Future<String> sendTransaction(String chain, String key, Uint8List data) async {
  var baseUrl =
      '$apiServer/api/v$apiVersion/$chain/data?key=$key&is_trans=true&broadcast=true';

  HttpClient httpClient = new HttpClient();
  HttpClientRequest request = await httpClient.postUrl(Uri.parse(baseUrl));
  request.add(data);
  HttpClientResponse response = await request.close();

  if (response.statusCode == HttpStatus.ok) {
    // print('请求成功');
    // print('chain:$chain,key:$key'); //打印头部信息
    // print("post------$responseBody");
    return key;
  }
  String responseBody = await response.transform(utf8.decoder).join();
  throw "$responseBody";
  // throw 'Out of llamas!';
  // assert(response.statusCode == HttpStatus.ok);
  // return '$responseBody';
}

Future<List<int>> getDBData(num chain, String structName, String key) async {
  var baseUrl = '$apiServer/api/v$apiVersion/$chain/data?key=$key&app_name=$core&is_db_data=true';
  baseUrl += '&raw=true&struct_name=$structName';
  try {
    Response<List<int>> rs = await Dio().get<List<int>>(
      baseUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    if (rs.statusCode == HttpStatus.ok) {
      return rs.data;
    }
  } catch (exception) {
    print('Failed get,$baseUrl,' + exception.toString());
  }

  return null;
}
