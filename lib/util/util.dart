import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

const core = 'e4a05b2b8a4de21d9e6f26e9d7992f7f33e89689f3015f3fc8a3a3278815e28c';

String apiServer = 'http://govm.net';
String unit = 'tc';
num apiVersion = 1;
var allChains = [1, 2];
Map<String, _UpdateItem> accounts = {};
Map<String, _UpdateItem> locks = {};
const _updateLimit = 10000;

class _UpdateItem {
  int lastTime;
  num balance;
  _UpdateItem(this.lastTime, this.balance);
}

num getBaseOfUnit({String u = 'tc'}) {
  switch (u) {
    case 'tc':
      return 1000000000000;
      break;
    case 't9':
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

Future<num> getAccountLocked(num chain, String address) async {
  var now = DateTime.now().millisecondsSinceEpoch;
  var have = locks['$chain.$address'];
  if (have != null) {
    if (have.lastTime + _updateLimit > now) {
      print('hit cache(locked)');
      return have.balance;
    }
  }
  var baseUrl =
      '$apiServer/api/v$apiVersion/$chain/data?key=$address&app_name=$core&is_db_data=true';
  var lockUrl = baseUrl + '&struct_name=statCoinLock';
  var unlockUrl = baseUrl + '&struct_name=statCoinUnlock';
  var httpClient = new HttpClient();
  // print("getAccountLocked:$lockUrl");
  num result = 0;
  try {
    var request = await httpClient.getUrl(Uri.parse(lockUrl));
    var response = await request.close();
    if (response.statusCode == HttpStatus.ok) {
      var json = await response.transform(utf8.decoder).join();
      var data = jsonDecode(json);
      String val = data['value'];
      // print("locked:"+data.toString());
      if (val != null && val != '') {
        var lock = int.parse(val, radix: 16);
        int unlock = 0;
        request = await httpClient.getUrl(Uri.parse(unlockUrl));
        response = await request.close();
        if (response.statusCode == HttpStatus.ok) {
          var json = await response.transform(utf8.decoder).join();
          var data = jsonDecode(json);
          String val = data['value'];
          // print("locked:"+data.toString());
          if (val != null && val != '') {
            unlock = int.parse(val, radix: 16);
            // print('getAccountLocked:$chain,$address,$result');
          }
        }
        result = lock - unlock;
        locks['$chain.$address'] =
            _UpdateItem(DateTime.now().millisecondsSinceEpoch, result);
        // print('getAccountLocked:$chain,$address,$result');
      }
    } else {
      print('Error get:\nHttp status ${response.statusCode}');
    }
  } catch (exception) {
    print('Failed get,$lockUrl,' + exception.toString());
  }

  return result;
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
  print("postTrans--${response.statusCode}----$responseBody");
  assert(response.statusCode == HttpStatus.ok);
  return '';
}

Future<List<int>> getDBData(num chain, String structName, String key) async {
  var baseUrl =
      '$apiServer/api/v$apiVersion/$chain/data?key=$key&app_name=$core&is_db_data=true';
  baseUrl += '&raw=true&struct_name=$structName';
  try {
    Response<List<int>> rs = await Dio().get<List<int>>(
      baseUrl,
      options: Options(
          responseType: ResponseType.bytes), 
    );
    if (rs.statusCode == HttpStatus.ok) {
      return rs.data;
    }
  } catch (exception) {
    print('Failed get,$baseUrl,' + exception.toString());
  }

  return null;
}

