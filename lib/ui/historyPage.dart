import 'package:flutter/material.dart';
import 'package:govm/generated/i18n.dart';
import 'package:govm/util/encode.dart';
import 'package:govm/util/util.dart' as util;
import 'package:govm/wallet/wallet.dart';
import 'package:hex/hex.dart';
import 'package:url_launcher/url_launcher.dart';

num _chain = 1;
Map<String, HistoryItem> historys = {};
const _outStruct = 'statTransferOut';
const _inStruct = 'statTransferIn';
const _moveStruct = 'statMove';

class HistoryItem {
  num count;
  Map<num, String> trans;
  HistoryItem(num c) {
    this.count = c;
    this.trans = {};
  }
}

class HistoryWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new HistoryWidgetState();
  }
}

class HistoryWidgetState extends State<HistoryWidget> {
  @override
  void initState() {
    super.initState();
    if (wallet.address != "") {
      for (var i in util.allChains) {
        update(i, '$i.${wallet.address}.$_outStruct', _outStruct);
        update(i, '$i.${wallet.address}.$_inStruct', _inStruct);
        update(i, '$i.${wallet.address}.$_moveStruct', _moveStruct);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(I18n.of(context).transHistory),
        ),
        body: DefaultTabController(
          length: 3,
          child: Column(
            children: <Widget>[
              Container(
                  color: Colors.blue,
                  child: TabBar(
                    indicatorWeight: 3.0,
                    indicatorColor: Colors.grey,
                    tabs: <Widget>[
                      Tab(text: I18n.of(context).tranferIn),
                      Tab(text: I18n.of(context).tranferOut),
                      Tab(text: I18n.of(context).move),
                    ],
                  )),
              Expanded(
                  flex: 1,
                  child: TabBarView(
                    children: <Widget>[
                      transferWidget(_inStruct),
                      transferWidget(_outStruct),
                      transferWidget(_moveStruct),
                      // transferOutWidget(),
                    ],
                  ))
            ],
          ),
        ));
  }

  List<Widget> getTransList(String hKey) {
    var trans;
    var item = historys[hKey];
    if (item == null || item.count <= 0) {
      trans = new List<Widget>();
      trans.add(Text(I18n.of(context).noRecord));
    } else {
      trans = new List<Widget>();
      for (var i = item.count; i + 10 > item.count && i > 0; i--) {
        var k = item.trans[i];
        if (k == null) {
          continue;
        }
        var url = '${util.apiServer}/transaction.html?chain=$_chain&key=$k';
        trans.add(InkWell(
            child: Container(
                padding: const EdgeInsets.all(2.0),
                child: Text('$i:' + k,
                    overflow: TextOverflow.ellipsis,
                    style: new TextStyle(
                        fontSize: 18, decoration: TextDecoration.underline))),
            onTap: () => launch(url)));
      }
    }
    return trans;
  }

  Widget transferWidget(String struct) {
    var hKey = '$_chain.${wallet.address}.$struct';
    var trans;
    var _chains = util.allChains.map((num i) {
      return DropdownMenuItem(
        value: i,
        child: Text(I18n.of(context).chain+'$i'),
      );
    }).toList();

    var chainW = DropdownButton(
      isExpanded: true,
      value: _chain,
      items: _chains,
      onChanged: (num selected) {
        _chain = selected;
        hKey = '$selected.${wallet.address}.$struct';
        update(_chain, hKey, struct);
        trans = getTransList(hKey);
        setState(() {});
      },
    );
    // print('history key:$hKey');
    trans = getTransList(hKey);

    return Scaffold(
      body: Scrollbar(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: new Form(
              child: new Column(
                children: <Widget>[
                  chainW,
                  ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20.0),
                    children: trans,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {
          update(_chain, hKey, struct);
        },
        tooltip: I18n.of(context).refresh,
        child: Icon(Icons.refresh),
      ),
    );
  }

  update(num chain, String hKey, String struct) {
    util
        .getDBData(
            chain, struct, wallet.address)
        .then((List<int> data) {
      if (data == null) {
        print("not history:$hKey");
        return;
      }
      var count = bytes2BigInt(data).toInt();
      var have = historys[hKey];
      print('$struct:$count');
      if (have == null) {
        have = HistoryItem(0);
        historys[hKey] = have;
      }
      if (count != have.count) {
        have.count = count;
        historys[hKey] = have;
      }

      for (var i = count; i > 0 && i + 10 > count; i--) {
        if (have.trans[i] != null && have.trans[i] != "") {
          // print('exist trans:$i');
          continue;
        }
        var id = BigInt.from(i);
        var hexID = HEX.encode(bigInt2Bytes(id, len: 8));
        var key = wallet.address + hexID;
        // var key = '01ccaf415a3a6dc8964bf935a1f40e55654a4243ae99c709' + hexID;
        var lid = i;
        util.getDBData(chain, struct, key).then((List<int> data) {
          if (data == null) {
            print('fail to get trans:$lid');
            return;
          }
          var result = HEX.encode(data);
          if (data.length == 8) {
            result = "move_in,block id:" + bytes2BigInt(data).toString();
          }
          have = historys[hKey];
          have.trans[lid] = result;
          historys[hKey] = have;
          // print('$struct trans:$lid,key:$result,${data.length},$key');
          setState(() {});
        });
      }
    });
  }
}
